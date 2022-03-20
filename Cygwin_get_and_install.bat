@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

# Cygwinを公式からダウンロードし、Cygwinに(mingw32の)gccとclangをインストールしてhello worldをコンパイルし、それらのログを出力します

# スクリプトの動作ディレクトリを得る
function getScriptDir() {
  if ("$PSScriptRoot" -eq "") {
    $Pwd.Path # bat化した場合、$PSScriptRoot や $MyInvocation.MyCommand.Path や $PSCommandPath は空なので、bat起動時のカレントディレクトリで代用する
  } else {
    $PSScriptRoot
  }
}

# ログを記録開始する（処理時間計測を含む）
function startLog($filename) {
  $null = Start-Transcript $filename
  Get-Date # 呼び出し元で時間計測スタート時刻を記録する用
}

# ログを記録終了する
function endLog() {
  "かかった時間 : " + ((Get-Date) - $startTime).ToString("m'分's'秒'")
  Stop-Transcript
}

# 子プロセスを実行する
function execChild($commands) {
  $input | cmd.exe /c $commands
}

# rm -f する
function rm_f($filename) {
  if (Test-Path $filename) {
    $null = Remove-Item $filename -Force # powershellのrmは rm -f ができなくて紛らわしいので関数でwrapする
  }
}

# Cygwin公式からexeをダウンロードし、exe名を得る
function downloadCygwinExe() {
  $exeUrl = "https://www.cygwin.com/setup-x86_64.exe"
  $exeName = $exeUrl -replace 'https.*\/', ''
  $exeFullpath = "${cygwinInstDir}\install\${exeName}"
  rm_f $exeFullpath # 前回の残骸があってバグ検知できない、を防止する用
  $null = curl.exe -L $exeUrl --output $exeFullpath
  $exeFullpath
}

# Cygwinをインストールする
function installCygwin($exeFullpath) {
  $rootFullpath = "${cygwinInstDir}\cygwin64"
  $line =  "$exeFullpath"
  $line += " --root              $rootFullpath               "
  $line += " --local-package-dir $rootFullpath               "
  $line += " --site              $packageSite                "
  $line += " --quiet-mode                                    "
  $line += " --no-admin                                      "
  $line += " --wait                                          "
  $line += " --packages          libiconv,libiconv-devel,wget" # 必要最小限（後続shで必須のもの）のみに絞った
  execChild $line
}

# Cygwinに(mingw32の)gccとclangをインストールしてhello worldをコンパイルし、ログを得る
function installGccClang() {
  $Env:WD="${cygwinInstDir}\cygwin64\bin\"
  download_install_gcc_clang_sh $Env:WD

  pushd $Env:WD
    rm_f install_gcc_clang.log # msys2-auto-installに寄せた
    .\bash --login -c "/bin/install_gcc_clang.sh" # bash や bash.exe は認識されず、.\bash は認識された
  popd
}

# "gcc&clangインストール用sh" の実体をダウンロードし、/usr/binに配置する
function download_install_gcc_clang_sh($Env:WD) {
  rm_f ${Env:WD}install_gcc_clang.sh
  curl.exe -L $url_install_gcc_clang_sh --output ${Env:WD}install_gcc_clang.sh
  #cp ${scriptDir}\install_gcc_clang.sh ${Env:WD}install_gcc_clang.sh # sh開発用
}

function main() {
  # 開発時はここと download_install_gcc_clang_sh内 それぞれを適宜コメントアウトして効率化する
  $exeFullpath = downloadCygwinExe
  #$exeFullpath = "${cygwinInstDir}\install\setup-x86_64.exe" # 開発用（以降を開発するとき用）
  installCygwin $exeFullpath
  installGccClang
}


###
$packageSite="https://ftp.iij.ad.jp/pub/cygwin/"
$url_install_gcc_clang_sh = "https://raw.githubusercontent.com/cat2151/cygwin-auto-get-install/main/install_gcc_clang.sh"
$scriptDir = getScriptDir
$cygwinInstDir = "${scriptDir}\Cygwin_get_and_install" # batのあるディレクトリをできるだけ汚さない用
$startTime = startLog "${cygwinInstDir}\install\Cygwin_get_and_install.log"
main
endLog
