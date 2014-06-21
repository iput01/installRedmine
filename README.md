
Redmineのシェルインストーラー
======================

概要
------
シェルスクリプトでRedmineのインストールを楽に行えます。
以下のサイトのインストール方法をshファイルにまとめてみました。
http://blog.redmine.jp/articles/2_5/installation_centos/

-redmine-2.5.1
-ruby-2.0.0-p481
-mysql

準備
------
os: centos6.5
出来ればosインストール後、未使用のサーバーを用意してください。
mysql:
rootのパスワードとredmine userのパスワードを準備してください。

手順
------
インストールするOS上で**root**権限で実行してください。

### 1.Gitをインストールする
>
\# yum install -y git

### 2.Gitからコードを取得
>
\# git clone https://github.com/iput01/installRedmine

### 3.取得したコードの実行
>
\# cd installRedmine
\# sh setp1.sh

SELinuxの停止とrubyのアンインストールが行われます。
ここで、一旦、**再起動**をしてください。

### 4.インストール
>
\# sh step2.sh [domain_name] [mysql_root_password] [mysql_password]

domain_name, mysql_root_password, mysql_passwordはそれぞれ置き換えて入力してください。
インストールにはお使いの環境にもよりますが結構な時間がかかります。
また、途中、mysql_secure_installationによるmysqlの初期設定の入力などが必要です。
準備したパスワードや内容を適宜入力してください。

### 5.WEBから確認
ブラウザから以下のURLで確認する。Redmineの画面が表示されればOKです。
http://[ip address]

また、初期設定が必要になりますので、以下のURLを参考に初期設定を行ってください。
http://redmine.jp/tech_note/first-step/admin/

その他
--------
このコードを使用することに関する一切の責任は負えませんので、自己責任にてご使用ください。




