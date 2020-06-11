with days as
(SELECT date_trunc('month',grass_date) as month,
        cast(count(distinct grass_date) as double) as days
from order_mart__order_profile
where date_id >= date('2020-01-01')
group by 1
),

item_list as
(SELECT DISTINCT a.brand,
                 a.itemid,
                 b.main_category,
                 case when b.shopid in (37137599,111392667,116304162,116309859,50662979,120786510,219469859) then 'B2C'
                 when b.is_official_store = 1 then 'Mall'
                 else 'C2C' end as shop_type,
                 case when a.brand in ('coway 格威','Coway(格威)') then 'Coway'
                 when a.brand in ('Dyson','dyson','dyson 戴森','Dyson 戴森','Dyson(戴森)')  then 'Dyson'
                 when a.brand in ('LG','lg','LG 樂金','LG(樂金)','lg(樂金)','LG樂金','日立LG','樂金 LG') then 'LG'
                 when a.brand in ('國際 Panasonic','國際牌 (Panasonic)','國際牌 Panasonic','國際牌Panasonic','國機牌 Panasonic','Panasonic','panasonic','Panasonic ','Panasonic 松下','panasonic 松下 huatai 華太 gp 超霸','Panasonic 松下電器','Panasonic 國牌','Panasonic 國際','Panasonic 國際牌','Panasonic(國際牌)','panasonic(國際牌)','Panasonic出品','Panasonic松下','Panasonic國際','Panasonic國際牌','Panasonic國際牌出品') then 'Panasonic'
                 else null end as brand_tag
FROM shopee_bi_tw_brand_info a
JOIN item_profile b ON a.itemid = b.itemid
WHERE a.brand in ('coway 格威','Coway(格威)','Dyson','dyson','dyson 戴森','Dyson 戴森','Dyson(戴森)','LG','lg','LG 樂金','LG(樂金)','lg(樂金)','LG樂金','日立LG','國際 Panasonic','國際牌 (Panasonic)','國際牌 Panasonic','國際牌Panasonic','國機牌 Panasonic','樂金 LG','Panasonic','panasonic','Panasonic ','Panasonic 松下','panasonic 松下 huatai 華太 gp 超霸','Panasonic 松下電器','Panasonic 國牌','Panasonic 國際','Panasonic 國際牌','Panasonic(國際牌)','panasonic(國際牌)','Panasonic出品','Panasonic松下','Panasonic國際','Panasonic國際牌','Panasonic國際牌出品')
),

pv as
(SELECT date_trunc('month',a.grass_date) as month ,itemid,sum(pv_cd)/days as daily_pv
from traffic_mart_dws__product_exposure a
left join days b on date_trunc('month',a.grass_date) = b.month
where grass_date >= date('2020-01-01')
and itemid in (SELECT distinct itemid from item_list)
group by 1,2,b.days
),

orders as
(SELECT date_trunc('month',a.grass_date) as month ,
        itemid,
        sum(order_fraction)/days as daily_orders,
        sum(gmv)/days as daily_gmv,
        sum(shopee_item_rebate + shopee_coin_rebate + pv_voucher_rebate_by_shopee + sv_voucher_rebate_by_shopee + coalesce(shopee_actual_shipping_rebate,shopee_actual_shipping_rebate,0))/days as daily_shopee_cost
from order_mart__order_item_profile a
left join days b on date_trunc('month',a.grass_date) = b.month
where date_id >= date('2020-01-01')
and itemid in (SELECT distinct itemid from item_list)
group by 1,2,b.days
)

select distinct month,
                brand_tag,
                shop_type,
                coalesce(item_count,0) as item_count,
                coalesce(selling_item_count,0) as selling_item_count,
                coalesce(daily_pv,0) as daily_pv,
                coalesce(daily_orders,0) as daily_orders,
                coalesce(daily_gmv,0) as daily_gmv,
                coalesce(daily_shopee_cost,0) as daily_shopee_cost

from
(
SELECT d.month,
       a.brand_tag,
       a.shop_type,
       count(distinct a.itemid) as item_count,
       count(distinct c.itemid) as selling_item_count,
       sum(daily_pv) as daily_pv,
       sum(daily_orders) as daily_orders,
       sum(daily_gmv) as daily_gmv,
       sum(daily_shopee_cost) as daily_shopee_cost


from item_list a join days d on 1 = 1
left join pv b on a.itemid = b.itemid and b.month = d.month
left join orders c on a.itemid = c.itemid and c.month = d.month
group by 1,2,3
)
order by 2,1
