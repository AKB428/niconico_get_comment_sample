
# ニコニコ動画のコメント取得ツール (Ruby)

```
ruby get_niconico_full_comment.rb [user_mail_adress] [password] [動画のID]
```

一部コメントはニコニコ会員じゃないと見れないようです。

APIを叩くならマナーとしてプレミアム会員になりましょう。

## ニコニコデータ サンプル

```
{"thread"=>{"resultcode"=>0, "thread"=>1444481838, "last_res"=>34314, "ticket"=>"0x8f887200", "revision"=>1681, "server_time"=>1447604264, "click_revision"=>100, "num_clicks"=>2}}
{"leaf"=>{"thread"=>1444481838, "count"=>21988}}
{"leaf"=>{"thread"=>1444481838, "leaf"=>1, "count"=>12326}}
{"view_counter"=>{"video"=>905443, "id"=>"sm27341580", "mylist"=>16722}}
{"chat"=>{"thread"=>1444481838, "no"=>33315, "vpos"=>8938, "date"=>1446732635, "mail"=>"pink 184", "user_id"=>"NWc5i7twOD1T1Sh3_1FProv4xqk", "anonymity"=>1, "leaf"=>1, "content"=>"さあ"}}
{"chat"=>{"thread"=>1444481838, "no"=>33316, "vpos"=>502, "date"=>1446732644, "mail"=>"pink 184", "user_id"=>"NWc5i7twOD1T1Sh3_1FProv4xqk", "anonymity"=>1, "content"=>"お"}}
```


## 検証動画

### 通常動画

* ご注文はうさぎですか？？ OP sm27341580
* ご注文はうさぎですか？？ ED sm27341702

## 公式チャンネル

■ 課金動画でもコメントは無料で取得可能

http://ch.nicovideo.jp/gochiusa2

* ご注文はうさぎですか？？ 1話 1444806625 [x]
* ご注文はうさぎですか？？ 2話 1445401285 [x]
* ご注文はうさぎですか？？ 3話 1446178642 [x]
* ご注文はうさぎですか？？ 4話 1446611605 [x]
* ご注文はうさぎですか？？ 5話 1447212383
* ご注文はうさぎですか？？ 6話 1447818565 [x]


