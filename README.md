# ニコニコ動画のコメント取得ツール (Ruby)

## 通常動画 movie_client.rb

```
ruby movie_client.rb [user_mail_adress] [password] [動画のID]
```

一部コメントはニコニコ会員じゃないと見れないようです。

APIを叩くならマナーとしてプレミアム会員になりましょう。

### 通常動画

* ご注文はうさぎですか？？ OP sm27341580
* ご注文はうさぎですか？？ ED sm27341702


## 公式チャンネル channel_client.rb

```
ruby channel_client.rb user_email password lvXXXX
```


■ 課金動画でもコメントは無料で取得可能

http://ch.nicovideo.jp/gochiusa2

* ご注文はうさぎですか？？ 1話 1444806625 [x]
* ご注文はうさぎですか？？ 2話 1445401285 [x]
* ご注文はうさぎですか？？ 3話 1446178642 [x]
* ご注文はうさぎですか？？ 4話 1446611605 [x]
* ご注文はうさぎですか？？ 5話 1447212383 [x]
* ご注文はうさぎですか？？ 6話 1447818565 [x]

http://ch.nicovideo.jp/gochiusa

* ご注文はうさぎですか？ 1話 1397552685

## ニコ生 live_client.rb

```
yum install gcc-c++
bundle install
bundle exec ruby live_client.rb user_email password lvXXXX
```

#### チケット不要

http://ch.nicovideo.jp/acaric-techtalk

* アカリクvol7 lv241487902

http://com.nicovideo.jp/community/co1775865

* ひよとみさぎノ罪生放送 lv242664075



## ニコニコ実況 jikkyo_client.rb

```
yum install gcc-c++
bundle install
bundle exec ruby jikkyo_client.rb user_email password jk1
```

http://jk.nicovideo.jp/

チャンネル

jk1, jk2, jk4–jk9


### GoogleBigQueryとの連携

#### ファイルをコピー
```
gsutil -m cp comments/*.tsv gs://nico_comment/jk_comment_jk89_b211
```

#### テーブル定義
```
thread: STRING ,no: STRING,vpos: STRING,date: STRING,mail: STRING,user_id: STRING,premium: STRING,anonymity: STRING,leaf: STRING,fork: STRING,deleted: STRING,content: STRING
```

#### テーブルの型を変換
```
SELECT
INTEGER(thread) as thread,
INTEGER(no) as no,
INTEGER(vpos) as vpos,
INTEGER(date) as date,
mail,
user_id,
content
FROM [niconico_comment.jk8_9_bs211C]

```

