# 各種パラメータ
param(
[string]$url   = "http://ルータのIPアドレス/index.cgi/sp/index_contents",
[string]$user  = "ユーザID",
[string]$pass  = "パスワード"
)

# 変数宣言を強制
set-psdebug -strict

# エラーがあった時点で処理終了
$ErrorActionPreference = "stop"

# バッテリ残量取得
# 引数1 ：Responseオブジェクト
# 戻り値：バッテリ残量文字列
function script:GetBatteryStatus($response){
    # バッテリ残量の格納されたLI要素を取得
    $li_status = $response.ParsedHtml.getElementById("rightStatusArea")

    # LI要素の中から先頭のLI要素を取得
    $li_1st = $li_status.getElementsByTagName("li")| select -First 1

    # XXX%のみを切り出し
    if ( $li_1st.innerHTML -match "\d+%") {
        return $matches[0]
    }
    
    # 取得できなければ"--"を返却
    return "--"
}

# 通信量取得
# 引数1 ：Responseオブジェクト
# 戻り値：通信量文字列
function script:GetCommunicationStatus($response){
    # 通信量の格納されたDIV要素を取得
    $div_article = $response.ParsedHtml.getElementById("article01")

    # DIV要素の中から先頭のTD要素を取得
    $td_1st = $div_article.getElementsByTagName("td")| select -First 1

    return $td_1st.innerHTML
}

function script:Main($url,$user,$pass){
    # ユーザID,パスワードからBASIC認証情報を作成
    $secure_passwd = ConvertTo-SecureString $pass -AsPlainText -Force
    $credential    = New-Object PSCredential $user, $secure_passwd

    # HTMLを取得(パース済み)
    $response = Invoke-WebRequest $url -Credential $credential
    
    $battery_status = GetBatteryStatus $response
    $communication_status = GetCommunicationStatus $response
    
    $message = "バッテリ残量：$battery_status`r`n通信量　　：$communication_status"

    # ダイアログ表示
    Add-Type -AssemblyName System.Windows.Forms;
    [System.Windows.Forms.MessageBox]::Show($message, "MR04LN STATUS","OK","Information")
}

Main $url $user $pass
