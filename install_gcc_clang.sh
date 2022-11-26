#!/usr/bin/env bash
set -e    # エラーを検知する用
set -x    # 何が実行されているかログでわかりやすくする用
SECONDS=0 # 時間計測用

# apt-cyg のインストール（perlのインストール用ほか、パッケージとモジュールのインストール管理用）
# https://qiita.com/fujisystem/items/64c33f9cf33fdd71555c
installAptCyg() {
  installAptCygSub
  if [ $? -ne 0 ]; then
    # apt-cyg -m が以下のエラーになることがある。対策はapt-cygをrmしてインストールしなおすこと。これは --version で検知できない。
    #   Error: TRUSTEDKEY_CYGWIN has been updated, maybe. But sometimes it may has been cracked. Be careful !!!
    rm /usr/local/bin/apt-cyg
    installAptCygSub
    if [ $? -ne 0 ]; then
      echo "apt-cygのインストールに失敗しました"
      exit 1
    fi
  fi
}

installAptCygSub() {
  # [前提] Cygwin_get_and_install.bat の installCygwin にて必須packageがinstall済みであること。なおこの関数にその処理の集約を試みたが中断した（$packageSite を持ってくる等かえって複雑になりそうなため）
  wget https://raw.githubusercontent.com/kou1okada/apt-cyg/master/apt-cyg
  chmod 755 apt-cyg
  mv apt-cyg /usr/local/bin/
  apt-cyg -m ftp://ftp.iij.ad.jp/pub/cygwin/ update
}

# perl のインストール（cpanmのインストール用ほか）
installPerl() {
  apt-cyg install perl_base # 20221103現在、ないとperl.exeがinstallされなかった
  apt-cyg install perl
  perl --version
  if [ $? -ne 0 ]; then
    echo "perlのインストールに失敗しました"
    exit 1
  fi
}

# cpanm のインストール（String::Randomのインストール用ほか、perlのモジュールのインストール管理用）
# https://gordiustears.net/cygwin-%E3%81%AB-cpanm-%E3%82%92%E3%82%A4%E3%83%B3%E3%82%B9%E3%83%88%E3%83%BC%E3%83%AB/
installCpanm() {
  installCpanmSub
  if [ $? -ne 0 ]; then
    # cpanm --version が以下のエラーになることがある。対策は再インストールしなおすこと。
    #   /usr/local/bin/cpanm: 行 1: 予期しないトークン `<' 周辺に構文エラーがあります
    #   /usr/local/bin/cpanm: 行 1: `<html><body><h1>504 Gateway Time-out</h1>'
    installCpanmSub
    if [ $? -ne 0 ]; then
      echo "cpanmのインストールに失敗しました"
      exit 1
    fi
  fi
}

installCpanmSub() {
  cd /usr/local/bin
  curl -LOk http://xrl.us/cpanm
  chmod.exe +x cpanm
  cpanm --version
}

installGccMingw() {
  apt-cyg install mingw64-x86_64-gcc-core
  x86_64-w64-mingw32-gcc --version

  apt-cyg install mingw64-x86_64-gcc-g++
  x86_64-w64-mingw32-g++ --version

  apt-cyg install gdb
  gdb --version

  apt-cyg install make  # テストはしないが必須級なのでinstallする。なおMSYS2のほうは明示しなくてもinstallされていた
  make --version

  apt-cyg install cmake # make同様必須級なのでinstallする
  cmake --version
}

installClangMingw() {
  apt-cyg install mingw64-x86_64-clang
  x86_64-w64-mingw32-clang   --version
  x86_64-w64-mingw32-clang++ --version
}

printSeconds() { # 引数 SECONDS
  ((sec=${1}%60, min=${1}/60))
  echo $(printf "かかった時間 : %02d分%02d秒" ${min} ${sec})
}

createSourceFile() { # 引数 : $cName, $cppName
  cName=$1
  cppName=$2
  pushd /usr/bin
  cat <<EOS > $cName
#include <stdio.h>
int main() { printf("hello, world C\n"); }
EOS

  cat <<EOS > $cppName
#include <iostream>
int main() { std::cout << "hello, world C++\n"; }
EOS
  popd
}

build() { # 引数 : compiler, sourceName, option
  compiler=$1
  sourceName=$2
  option=$3
  exeName=${compiler}_${sourceName}.exe
  echo "---"
  echo "$compiler"
  rm -f $exeName # コンパイル失敗時に状況をわかりやすくする用（以前生成したものが残っているとわかりづらいので）
  ls -al --color $sourceName
  $compiler -o $exeName $sourceName -ggdb $option
  ls -al --color $exeName
  gdb $exeName --eval-command=list --batch
  $exeName
  echo $?
  mv -f $exeName $WD../../install # hello world exeを cygwin64/../install に移動する
}

buildHelloWorld() {
  cName=hello_c.c
  cppName=hello_c++.cpp

  pushd /usr/bin
    createSourceFile $cName $cppName
    # Cygwinのgcc/g++は、mingw32を使う。そうしないとDLL依存するexe（DLLのない場所で動かない）が出力されてしまう
    build x86_64-w64-mingw32-gcc     $cName   "-v"
    build x86_64-w64-mingw32-g++     $cppName "-v -static -lstdc++ -lgcc -lwinpthread"
    build x86_64-w64-mingw32-clang   $cName   "-v"
    build x86_64-w64-mingw32-clang++ $cppName "-v -static -lstdc++ -lgcc -lwinpthread"
    mv -f $cName $cppName $WD../../install # hello worldソースを cygwin64/../install に移動する
  popd
}

createCygwin64Bat() {
  # cygwin64/../に、"cygwin.batを起動するbat" を生成する。msys2-auto-installと似たイメージで即席で使える用。
  cat <<EOS | iconv -f UTF-8 -t CP932 | perl -pe 's/\n/\r\n/' > ${WD}../../cygwin64.bat
@echo off
pushd cygwin64
call cygwin.bat
popd
EOS
}

addAliasToProfile() {
  # bashログインしgccやclangをタイプし、(mingwの)gccやclangがインストールされているか確認できる用
  echo '#'>> ~/.bash_profile
  echo 'alias gcc="echo （CygwinのgccはDLL依存のため、かわりにx86_64-w64-mingw32-gccを使います）;x86_64-w64-mingw32-gcc"'>> ~/.bash_profile
  echo 'alias g++="echo （Cygwinのg++はDLL依存のため、かわりにx86_64-w64-mingw32-g++を使います）;x86_64-w64-mingw32-g++"'>> ~/.bash_profile
  echo 'alias clang="echo （CygwinのclangはDLL依存のため、かわりにx86_64-w64-mingw32-clangを使います）;x86_64-w64-mingw32-clang"'>> ~/.bash_profile
  echo 'alias clang++="echo （Cygwinのclang++はDLL依存のため、かわりにx86_64-w64-mingw32-clang++を使います）;x86_64-w64-mingw32-clang++"'>> ~/.bash_profile
}

main() {
  # 開発時はここと "末尾のsh削除" それぞれを適宜コメントアウトして効率化する
  installAptCyg
  installPerl
  installCpanm
  installGccMingw
  installClangMingw
  rebaseall # exeを実行するとエラーになる問題の対策用（CygwinとWindowsの環境依存不具合）
  buildHelloWorld
  createCygwin64Bat
  addAliasToProfile
  printSeconds ${SECONDS}
}


###
if [[ "$WD" == "" ]]; then exit; fi # コード流用用にmsys2-auto-installに寄せる（なおcygwin公式batは、MSYS2の$WD的情報を得られない）
main 2>&1 | tee $WD../../install/install_gcc_clang.log
rm -f /usr/bin/install_gcc_clang.sh # 自分自身を掃除する
