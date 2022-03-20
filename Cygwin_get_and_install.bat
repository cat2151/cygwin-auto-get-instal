@powershell -NoProfile -ExecutionPolicy Unrestricted "$s=[scriptblock]::create((gc \"%~f0\"|?{$_.readcount -gt 1})-join\"`n\");&$s" %*&goto:eof

# Cygwin����������_�E�����[�h���ACygwin��(mingw32��)gcc��clang���C���X�g�[������hello world���R���p�C�����A�����̃��O���o�͂��܂�

# �X�N���v�g�̓���f�B���N�g���𓾂�
function getScriptDir() {
  if ("$PSScriptRoot" -eq "") {
    $Pwd.Path # bat�������ꍇ�A$PSScriptRoot �� $MyInvocation.MyCommand.Path �� $PSCommandPath �͋�Ȃ̂ŁAbat�N�����̃J�����g�f�B���N�g���ő�p����
  } else {
    $PSScriptRoot
  }
}

# ���O���L�^�J�n����i�������Ԍv�����܂ށj
function startLog($filename) {
  $null = Start-Transcript $filename
  Get-Date # �Ăяo�����Ŏ��Ԍv���X�^�[�g�������L�^����p
}

# ���O���L�^�I������
function endLog() {
  "������������ : " + ((Get-Date) - $startTime).ToString("m'��'s'�b'")
  Stop-Transcript
}

# �q�v���Z�X�����s����
function execChild($commands) {
  $input | cmd.exe /c $commands
}

# rm -f ����
function rm_f($filename) {
  if (Test-Path $filename) {
    $null = Remove-Item $filename -Force # powershell��rm�� rm -f ���ł��Ȃ��ĕ���킵���̂Ŋ֐���wrap����
  }
}

# Cygwin��������exe���_�E�����[�h���Aexe���𓾂�
function downloadCygwinExe() {
  $exeUrl = "https://www.cygwin.com/setup-x86_64.exe"
  $exeName = $exeUrl -replace 'https.*\/', ''
  $exeFullpath = "${cygwinInstDir}\install\${exeName}"
  rm_f $exeFullpath # �O��̎c�[�������ăo�O���m�ł��Ȃ��A��h�~����p
  $null = curl.exe -L $exeUrl --output $exeFullpath
  $exeFullpath
}

# Cygwin���C���X�g�[������
function installCygwin($exeFullpath) {
  $rootFullpath = "${cygwinInstDir}\cygwin64"
  $line =  "$exeFullpath"
  $line += " --root              $rootFullpath               "
  $line += " --local-package-dir $rootFullpath               "
  $line += " --site              $packageSite                "
  $line += " --quiet-mode                                    "
  $line += " --no-admin                                      "
  $line += " --wait                                          "
  $line += " --packages          libiconv,libiconv-devel,wget" # �K�v�ŏ����i�㑱sh�ŕK�{�̂��́j�݂̂ɍi����
  execChild $line
}

# Cygwin��(mingw32��)gcc��clang���C���X�g�[������hello world���R���p�C�����A���O�𓾂�
function installGccClang() {
  $Env:WD="${cygwinInstDir}\cygwin64\bin\"
  download_install_gcc_clang_sh $Env:WD

  pushd $Env:WD
    rm_f install_gcc_clang.log # msys2-auto-install�Ɋ񂹂�
    .\bash --login -c "/bin/install_gcc_clang.sh" # bash �� bash.exe �͔F�����ꂸ�A.\bash �͔F�����ꂽ
  popd
}

# "gcc&clang�C���X�g�[���psh" �̎��̂��_�E�����[�h���A/usr/bin�ɔz�u����
function download_install_gcc_clang_sh($Env:WD) {
  rm_f ${Env:WD}install_gcc_clang.sh
  curl.exe -L $url_install_gcc_clang_sh --output ${Env:WD}install_gcc_clang.sh
  #cp ${scriptDir}\install_gcc_clang.sh ${Env:WD}install_gcc_clang.sh # sh�J���p
}

function main() {
  # �J�����͂����� download_install_gcc_clang_sh�� ���ꂼ���K�X�R�����g�A�E�g���Č���������
  $exeFullpath = downloadCygwinExe
  #$exeFullpath = "${cygwinInstDir}\install\setup-x86_64.exe" # �J���p�i�ȍ~���J������Ƃ��p�j
  installCygwin $exeFullpath
  installGccClang
}


###
$packageSite="https://ftp.iij.ad.jp/pub/cygwin/"
$url_install_gcc_clang_sh = "https://raw.githubusercontent.com/cat2151/cygwin-auto-get-install/main/install_gcc_clang.sh"
$scriptDir = getScriptDir
$cygwinInstDir = "${scriptDir}\Cygwin_get_and_install" # bat�̂���f�B���N�g�����ł��邾�������Ȃ��p
$startTime = startLog "${cygwinInstDir}\install\Cygwin_get_and_install.log"
main
endLog
