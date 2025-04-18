# FE.tcl --.fe.dirs.t state disabled;.fe.files.t state disabled;
#
# GUI File explorer (FE) for ttk package
#
#  Copyright (c) 2020 Vladimir Orlov
# email: vorlov@lissi.ru

package require Tk 8.6.0 9
package require svgwidgets

package provide tkfe_svg 1.0

package require msgcat
namespace import msgcat::mc
namespace import -force msgcat::mcset

namespace eval FE {
  set ::SelDir ""
  set ::SelFil ""
if {![info exist ::FE::folder]} {
  array set ::FE::folder [list]
  set ::FE::folder(details) 0
  set ::FE::folder(foldersfirst) 1
  set ::FE::folder(sepfolders) 0
#  set ::FE::folder(reverse) 0
  set ::FE::folder(column) "#0"
  set ::FE::folder(direction) 0
  set ::FE::displaycolumns(size) 1
  set ::FE::displaycolumns(date) 0
  set ::FE::displaycolumns(permissions) 0
}
  ###################################################################
  mcset ru "No access" "Нет доступа"
  mcset ru "Create directory" "Создать каталог"
  mcset ru "Rename directory" "Переименовать каталог"
  mcset ru "Create an empty file" "Создать пустой файл"
  mcset ru "Delete file" "Удалить файл"
  mcset ru "Rename file" "Переименовать файл"
  mcset ru "Delete directory" "Удалить каталог"
  mcset ru "Enter a new folder name" "Введите новое имя папки"
  mcset ru "Enter a new file name" "Введите новое имя файла"
  mcset ru "Enter a name for new folder" "Введите имя новой папки"
  mcset ru "Enter a new file name" "Введите имя файла"
  mcset ru "Detailed View" "Расширенный список"
  mcset ru "Short View" "Только имена"
  mcset ru "Sorting" "Сортировка"
  mcset ru "Data composition" "Состав данных"
  mcset ru "Current directory" "Текущий каталог"
  mcset ru "Go up" "Перейти вверх"
#  mcset ru "Go prev" "В предыдущую папку"
#  mcset ru "Go next" "В следующую папку"
  mcset ru "Go prev" ""
  mcset ru "Go next" ""
  mcset ru "Go adddir" "Создать каталог"
  mcset ru "Go addfile" "Создать пустой файл"
  mcset ru "Go update" "Обновить"
  mcset ru "Go configure" "Внешний вид"
  mcset ru "Go hiddencb" "Показать скрытые папки/файлы"
  mcset ru "Go nohiddencb" "Скрыть скрытые папки/файлы"
  mcset ru "Go home" "В домашний каталог"
  mcset ru "Selected directory" "Выбранный каталог"
  mcset ru "Selected file" "Выбранный файл"
  mcset ru "Selected file/directory" "Выбранный файл/каталог"
  mcset ru "Choose directory" "Выберите каталог"
  mcset ru "Choose folder" "Выберите папку"
  mcset ru "Choose file" "Выберите файл"
  mcset ru "Cancel" "Отмена"
  mcset ru "Done" "Готово"
  mcset ru "Folders and files" "Папки и файлы"
  mcset ru "Folders" "Папки"
  mcset ru "Files" "Файлы"
  mcset ru "File" "Размер"
  mcset ru "Permissions" "Права"
  mcset ru "Size" "Размер"
  mcset ru "Date" "Дата"
  mcset ru "Add hidden folders" "Добавить скрытые папки"
  mcset ru "Hide hidden folders" "Убрать скрытые папки"
  mcset ru "File filter:" "Фильтр файлов:"
  mcset ru "Tools" "Инструменты"
  mcset ru "Change language" "Сменить язык"
  mcset ru "Select PKCS11 library" "Выберите библиотеку PKCS11"
  mcset ru "Detailed View" "Расширенный список"
  mcset ru "Short View" "Только имена"

  ttk::style configure Treeview  -background snow  -padding 0
#   -arrowsize 20
  ttk::style configure TCheckbutton  -background snow  -padding {1m 0 0 0}

##############Image fsdialog#################################
# Images for the configuration menu

image create photo fe_blank16 -height 16 -width 16
option add *TkFDialog*Menu.Image fe_blank16

image create photo fe_tick16_old -data {
R0lGODlhEAAQAMIAAExOTFRSVPz+/AQCBP///////////////yH5BAEKAAQALAAAAAAQABAA
AAM4CAHcvkEAQqu18uqat+4eFoTEwE3eYFLCWK2lelqyChMtbd84+sqX3IXH8pFwrmNPyRI4
n9CoIAEAOw==}

image create photo fe_tick16 -data {
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAACXBIWXMAAA7EAAAO
xAGVKw4bAAAAB3RJTUUH4wIBDAIJ3IjUywAAAB1pVFh0Q29tbWVudAAAAAAAQ3Jl
YXRlZCB3aXRoIEdJTVBkLmUHAAAAg0lEQVQoz2N8+eFTxZkfdz79ZyAEFLgZekw5
GBN3v7Ll++alwMnNzY1fw9b7X7c++ct05/N/YlQzMDB4K3I/+M7MwsDAAFHttesr
HtXb3KAmMjGQCEY1DA4NLJhxScAGRW6Grfe/EqN017PfKjwMjC/ffSw5+fXBd2aC
GlR4GIrlPwEARYApx4EpM+MAAAAASUVORK5CYII=
}
image create photo fe_unchecked_tick16  -data {
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAACXBIWXMAAA7EAAAO
xAGVKw4bAAAAB3RJTUUH4wIBDAwy8wAQYQAAAB1pVFh0Q29tbWVudAAAAAAAQ3Jl
YXRlZCB3aXRoIEdJTVBkLmUHAAAAdUlEQVQoz2N8++nTjsc/3v38z0AICLAweMpy
MC698kqK8ZumCCc3Nzd+DVfffL314S/Tu1//iVHNwMCgLcL98R8zEwMDAzGq4YCJ
gUQwqmGoahBgYbj25isxSu98+C3IxsD45v3HbQ+/fvzHTFCDEBuDIesnAE3cJiD1
JFxnAAAAAElFTkSuQmCC
}


image create photo fe_radio16_old -data {
R0lGODlhEAAQAMIAAJyZi////83OxQAAAP///////////////yH5BAEKAAEALAAAAAAQABAA
AAMtGLrc/jCAOaNsAGYn3A5DuHTMFp4KuZjnkGJK6waq8qEvzGlNzQlAn2VILC4SADs=}

image create photo fe_radio16 -data {
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAACXBIWXMAAA7EAAAO
xAGVKw4bAAACYUlEQVQ4jZWUPU8UURSGn3MvO7NAyFCgC7uJFCTESjuDigSDLAUE
t9YfYCig5TfYQoF/QOoNipEFIuIXsdPGhMSGuAuLFEwIsDPrzLFYIBA+Vk9zi3vP
c+99875HVJXLSkD687sewEqu1Ve49LBcBOrLlwcSIhMxZKOYJIA1VAwUqqpTq7nU
8pWg3rmdlmSss1V0OJtxtSflmHSjBaB0GLFWDuNCMZAEMl8x8uTjaNveOVDv3E5L
E/q1LWm6Jm+3JLq9GiA6usdKbV33I55/36vuHMY/D5A7x7CGY2Iy1tm2JtM1c99L
OFZ4txmw8Ctgcz8CoKPZMpRxeZh2mbnnJcY++13bB/FLYPTkRX358oAgi1N3W6Xb
s7z4sc/8RoUwPquDY2CkM8mzm82s+xETX3ZV0cHVXGrZACREJrIZV7s9y/vNgDcb
wTkIQBjD/EbAh62Abs+SzbjqGBkHMAISQ7Yn5RiApVJIEF9uiSBSFoshAD0px0TK
kIA09Od3vUhJphstCmwdaXJVbe5HKJButEQxyf78rmfqdv1jmZVcq28NldJhhADt
zbZuU0ezRah5yxoqK7lW3yiogcJauSbvYMbBNXIpxLXCYMYBYK0cxlZYOGJAVXWq
UAxk3Y/oa3cZ7nRxL/i0a2D4hsuDdpd1/w+FYiBhrNNwytmP8r9fXW8yQyeGLAUU
igGlg5r46SZL9siQYaSMffKr24fx26XH10bPgE4i0mi6Jm/Vici3vepO5WxEzodW
9WVVdeTK0Iq8rog8vTC0p6svXx5wjIxHytDpMWKFhTDW6bpj5Nzmfwy2v4HoOusK
Vn8dAAAAAElFTkSuQmCC
}

image create photo fe_radio16_unchecked  -data {
iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAYAAABWzo5XAAAACXBIWXMAAA7EAAAO
xAGVKw4bAAABxElEQVQ4jZ2UT28SQRiHf+87A4FdC0hiG6glHLyV1rPRXv0cnhWb
mH6OxgTRePRzeMZ48iBtjyYEzZJqwp8tu0tgZ14vYFp0BfqcJ89MJnl+JCJIovFl
UGE12wMA1rr7vFb8nnSWlkUfOp3M5GrrmEWOQXTX1TQFgCCWNEQGlqiR2bpqPKtW
J4mit1/7+ymyH8sO52sFdgspvnHJcGZxPrSBF9rRTPjpi4fFi79E79uDGsO0jrZ1
vpS9KVjGiyxaP+PRTPjxQkYigteff2TdO5lvR/d0aZVkQS+yaP0y3ngcPXj16H7E
AJBxsie7Dq98yXVKWUbZoULGyZ4AAAMgzagf5JSztmXOQU45ilEHQNxsX1aJxM2l
aVMPcmkCk7jN9mWVlVEVR3G8sWWOqzhWRlXW/5QVaKNMNzTQtxUExmqjTJfrhzsd
EQr8aXIqSfhTgRUE9cOdDgOQ2KJ55ptwU9GZb0JjqQlAGAAmYXTqhTLsRXZtSS+y
8EIZTsLoFLiWyLyzT0+2db5820QWLKLddSi/X1D/jnZkx15g/cRoF/yZEchLgIqu
lhkABDGlAOlD0Ejnxm/+OyPLvDvv79k4rgCrh+03NU/rBj9b11QAAAAASUVORK5C
YII=
}

# Images for ttk::getOpenFile, ttk::getSaveFile, ttk::getAppendFile

image create photo fe_next -data {
R0lGODlhFgAWAMYAADt1BDpzBFiJKb7ZpGaVOTx2A8HcqbfVm3ShSjt0BDp1BDx3Bb/apYe7
V7DSkIOtWzt0A8Dbpr/apL7ao7zZoXu0RXy0R6bMgo23Zz12CbzZoH+2Sn61SX21R3qzRHiy
QnaxPnOvOnCuNpjFb5e/cUV8ELnXnHiyQXaxP3WwPXCtNm2sMmqqLWaoKIm8WJ3FeEuBGLXV
l2+tNGGlIWanJ2urLWutLmqtK2irJ2SpIl+lHJ/GeFaKIjt1A6jNhU+aB06aBk+cBlKhCFWl
CViqDF6uEmCvFWGtFl2qE3e2Op3HdVWLIjt2BKPLflSjCFipClyvDF6zDWC2Dl+0DYTER5zK
cEqDFjt3A1eoClywDGG3DmW9EGfBEWnCE5XTWZjJZ0R9D6TLfqbPf6nUgazYgq/cg2nDEXPM
GqPfaY7DWj53CTlzBD13Ba7bg3HGH6fecn+0SqbWdmufOjhwBKTPelqNKTNmAk6DHi9dAzdu
A////////////////////////yH5BAEKAH8ALAAAAAAWABYAAAfGgH+Cg4SFhoeIiYgAio0B
Ao2JAQMEBZGGAQYHCAmNCgGgoAsMDQ4PEIoBEasREhMUFRYXGBmSGhsbHB0eHyAhIiMkJYgB
JifHKCkhKissLS4vMIcBMTItMzM0NTY3ODk6Jzs9mD4/QEBBQkNERUZHSElKTJhN50FOT1BR
UlJTVFVXptUDIgRLFi1buHTx8gUMsSZNwogZQ6aMmTNo0qhJtCYUKDZt3LyB0+mSoABk4siZ
Y3JQADp17LR0eQfPzEF5burcKSgQADs=}

image create photo fe_nextbw -data {
R0lGODlhFgAWAOcAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0N
DQ4ODg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8f
HyAgICEhISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDEx
MTIyMjMzMzQ0NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkND
Q0REREVFRUZGRkdHR0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVV
VVZWVldXV1hYWFlZWVpaWltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdn
Z2hoaGlpaWpqamtra2xsbG1tbW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5
eXp6ent7e3x8fH19fX5+fn9/f4CAgIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouL
i4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOTk5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2d
nZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaampqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+v
r7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5ubq6uru7u7y8vL29vb6+vr+/v8DAwMHB
wcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zMzM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT
09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f3+Dg4OHh4eLi4uPj4+Tk5OXl
5ebm5ufn5+jo6Onp6erq6uvr6+zs7O3t7e7u7u/v7/Dw8PHx8fLy8vPz8/T09PX19fb29vf3
9/j4+Pn5+fr6+vv7+/z8/P39/f7+/v///yH5BAEKAP8ALAAAAAAWABYAAAjUAP8JHEiwoMGD
CBMivKKwYZU3DRNWWcaHYcSCVZwVS2SloZUqIEFiYQYK2KWOEpupbLZsmTJLl3CFwiJRWaZM
mDBVoiQJkiNXqr4grHKMklFJkSA1WpTIUChYZQ5WIdbIkCBBhRItUoSoECBKsSwSrJJrjhw5
dPDsAUTIUCFBlcIarGLrLB09fwgdSpQI0ShZNOfWlYPHDyFFjyRRkvVKqFRbkHP1CkaMUidg
p7JIDAkyyzBNwTChvPivSrBehKaQHlgFl5wlq1mfKRJ7YJTauHMLDAgAOw==}

image create photo fe_prev -data {
R0lGODlhFgAWAOcAADp0BFSIJTx1Bzp0A2KSNLrWnz93Czt1BHGeRbXUmL/apTx0BH6qVa/R
joS5UrzZoEF7CzpzBD13CIu2Y6TLf3iyQniyQbnXnbzZob7ao7/apMDbpj92CkR7D5S8bJbD
a22sMW+tNHKvOXaxPnqzRH21R361SX+2SrvYn0mAFprDdIe6VWOmI2aoKGqqLW2sMnCtNnOv
OnWwPXaxP7jWmj52CTt1A1SIIJvEdHWxPlqhF16jHGGlIWSnJWmrK2uvLGqwKGevI2uvKXKy
NrTVlT11CDt3A1SKIJrEcVOdDVWeEFSeD1ekD1enC1mrCluuC1ywDFqqC6rThEmCFZXAbE6a
BlKgB1enCV+0DWK4DmS7D2O7D1+zDajUfkJ5DYy5YYa7U1elDFqsC2jBEWvGEmrFEmfBEWO6
D6rXfzx1CDx2B4GwU5TGY2GxFGC2Dq7dgLLhhLXmhrTlha/dg63Zgjx2CDpyA3WmRZ3Ob2m5
HK3bgEF9CTtzBDduA2aYNqHQdazYgTNlAleLJaPOeS1ZA0yBGzx0Bv//////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////////yH5BAEKAP8ALAAAAAAWABYAAAjgAP8JHEiwoMGD
CBMq/AdgYcIAAhwaHECggAGJBA8gSKDgIsZ/Cxg0cPAAQoSTJw8klDCBQgULFzBk0LChJgeE
HTx8ABFCxIgKJEqYOIHipsEUKlawaOHiBYwYMmZYsECjhkEbOHLo2MGjh48fQIIEETKESBGD
RpDASKJkCZMmTp5AgfIkipSzBgFQIVHFypUnWLJo2ZKFSxe8Br18ARNGDBYtY8iUMXMGTZqE
atawaePmDZw4cuDMoVNHoZ07ePLo2YPyJJ+Fffz8AVT6o8BAggbVtv2PUCFDvAn2CU7cdkAA
Ow==}

image create photo fe_prevbw -data {
R0lGODlhFgAWAOcAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0N
DQ4ODg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8f
HyAgICEhISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDEx
MTIyMjMzMzQ0NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkND
Q0REREVFRUZGRkdHR0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVV
VVZWVldXV1hYWFlZWVpaWltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdn
Z2hoaGlpaWpqamtra2xsbG1tbW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5
eXp6ent7e3x8fH19fX5+fn9/f4CAgIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouL
i4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOTk5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2d
nZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaampqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+v
r7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5ubq6uru7u7y8vL29vb6+vr+/v8DAwMHB
wcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zMzM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT
09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f3+Dg4OHh4eLi4uPj4+Tk5OXl
5ebm5ufn5+jo6Onp6erq6uvr6+zs7O3t7e7u7u/v7/Dw8PHx8fLy8vPz8/T09PX19fb29vf3
9/j4+Pn5+fr6+vv7+/z8/P39/f7+/v///yH5BAEKAP8ALAAAAAAWABYAAAjXAP8JHEiwoMGD
CBMq/GdlYcI2VxwatJLnmBaJBK8YIsbsIkaGk351UtalikmTERFm+WSLEqVjypYta0YzC0Iv
p1YtavRIEqVKmDBlSmbT4BhXnwYZSrQTUiSflIwVzehKEp8/ggglYsRIkaJFkYhhMYjFVSM7
ePDw6QNoECFCgwD5GjsxVSU5d/oMQrSz0aJDvega5BLqE59AiBpJsmRJUqNfKQ9iucTqUCJi
yJgtQ1ZMmOCDVBjRejTMy8mTC6P4uRXsM8YlcG65xiikTOSPA6Pg3s1bYEAAOw==}

image create photo fe_up -data {
R0lGODlhFgAWAMZ/ADpzBDt1Azt1BDx1Azp2BDt2BDx2Azx2BD52CT14BT14CD55
BUR7D0V8EEuBGE+FH1iKKFuOKU+bCGSUN1SdDlSeD1GgB1aeEVOhCVahDlmgFlqh
GGiaOVyiGlamCV6jHFenCVeoCmGlIV6oF2OmI1yqEWGoHGaoKHShSVyvDFywDGir
J2usLWysMXanSG+tNG+tNWWzGWC2DmG3DnKvOmG4DmK4Dm6zLHexQGa6FIKsWXO0
NGW9EHmzQ3e1O2a+EGa/EHm1QWe/EGy9HmfAEYKyVXK7KmnDEWrEEnm8On27QYO4
UIS4UXTBKWvGEoW5UmvHEoy2ZWzHE2zIE23JE23KE3zDOG7LFILBRY67ZG/MFI2+
X3HQFZa/cIfHSpbBbZTCaZXDapzDdprFcpzFdZzIcqLKfaDLeajRgKnTgK3RjarV
gazZgrXVmK/aha7bg6/cg6/dg7vXoLDeg7DfhLHfhLHghL7bo73coL/bpcDeosLh
pcTjpsXjqcbkqf///yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAW
ABYAAAfHgH+Cg4SFhoeIiYqLigYHjIcOZGMDkIQNYjQwXwyWfwhdTxsXPVkKkAZR
YCQfGhRLRQGLBDpmLSciHRUSWy4FiQYoajgvLCsmGBYZYRyVhxNtTEE+OzclISAe
I2URhxByeXd4SkkxKiopa2loZw+FAgDxCXpYRjI1NjNsC/EABIgA9njJwUMIESBw
ADACwMcKjyNQpjiho3ARAD9NgDjRwqWKnYqKLg75gYTKFSl1QCYC0MfNmzl17NSJ
oxJgv5vxPOncydNQIAA7}

image create photo fe_upbw -data {
R0lGODlhFgAWAOcAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0N
DQ4ODg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8f
HyAgICEhISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDEx
MTIyMjMzMzQ0NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkND
Q0REREVFRUZGRkdHR0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVV
VVZWVldXV1hYWFlZWVpaWltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdn
Z2hoaGlpaWpqamtra2xsbG1tbW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5
eXp6ent7e3x8fH19fX5+fn9/f4CAgIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouL
i4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOTk5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2d
nZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaampqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+v
r7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5ubq6uru7u7y8vL29vb6+vr+/v8DAwMHB
wcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zMzM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT
09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f3+Dg4OHh4eLi4uPj4+Tk5OXl
5ebm5ufn5+jo6Onp6erq6uvr6+zs7O3t7e7u7u/v7/Dw8PHx8fLy8vPz8/T09PX19fb29vf3
9/j4+Pn5+fr6+vv7+/z8/P39/f7+/v///yH5BAEKAP8ALAAAAAAWABYAAAjPAP8JHEiwoMGD
CBMqXMiw4cErWBwWLPPK1RWJAr+4etRIlReJWVR54oOn0qgsDa+AUjXoz547nDJdVHjFUq1F
hgT5wUOHVKOZDxP5mtRIEaJBeO7oWQUIaME9xDpZoiTpUSA/ffgEijXnIBxkzMJqyqSIkFlf
vXbVSlPwSpW3WZyBqpRo0SJFwbS8reKUYJVophw9iiQpErEqDKtI8/SI0iVMlowhXliFWqZI
ljZ5ynRsssLKkyBVyqTpUufE04YNM3asdTHPCffK3ouxdu2AADs=}

image create photo fe_home -data {
R0lGODlhFgAWAMYAAKQAAPR1deU5OeInJ+xGRvFMTPBRUfJVVeAmJvNbW/JeXntMSohaWN4m
JvNkZJldW4SFgpubmsCKitwmJvRsbPRmZp11c4+Qjbi5uMLCwbq6ucShodwlJfNjY6ONi5+g
nr+/vt7e3d3d3dfX18m1tZwICKefnaOjotra2urq6unp6efn59zQ0IQiIaGgnqKjodjY2Obm
5uTk5OPj4+Le3tvc21VXU3d4enZ5fXV1dXV2dvPz8+7u7n6Ae3+BfICCfeXl5XZ5fHmZw3eY
wnV4fPLy8u3t7YSGgYWHguLi4nV4e1+Gt0p2rnJ1evHx8ezs7IaIg4qIZYmIcODg4HF4gTRl
pG52gfDw8Ovr64eJhIiJfvn5+bGztri8wbq7vLm9waSkpO/v74iKhd7e3qKioqOjo2VnY5eZ
lJiZlpmalpmal/j4+P//////////////////////////////////////////////////////
/////////////////////////yH5BAEKAH8ALAAAAAAWABYAAAf+gH+Cg4QAAISIiYUBAYeK
j38AjIyOkIsCjAONloOSBAWZmpWPkgYHjZIIopCSCQqNCwySDauJkg4OjQ8QERKSE7WdARQV
jRYXGBkaG5IcwZEBHY0eHyAhISIjJCUBHJvCjSYnKCnlKiorLNzfgpItLi8wMSv0MTIyMzTc
o5E1Nv//0N3AkQOHjh38/tjgYaOHjx8/YgAJIiTHECJFbCSyYcTGkY9IZCRRsiQHkyZONCKy
8cQGFChRpCSZQqVKjipWrqgkZAOLjSxZtPiYsoVLFy9fwITZOchGChtioooZs4VMmatlRDAV
ZOOKmTNo0qjZwaOs2TVbFQJcyxYgp7cEcDkFAgA7}

image create photo fe_homebw -data {
R0lGODlhFgAWAOcAAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0N
DQ4ODg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8f
HyAgICEhISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDEx
MTIyMjMzMzQ0NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkND
Q0REREVFRUZGRkdHR0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVV
VVZWVldXV1hYWFlZWVpaWltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdn
Z2hoaGlpaWpqamtra2xsbG1tbW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5
eXp6ent7e3x8fH19fX5+fn9/f4CAgIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouL
i4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOTk5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2d
nZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaampqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+v
r7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5ubq6uru7u7y8vL29vb6+vr+/v8DAwMHB
wcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zMzM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT
09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f3+Dg4OHh4eLi4uPj4+Tk5OXl
5ebm5ufn5+jo6Onp6erq6uvr6+zs7O3t7e7u7u/v7/Dw8PHx8fLy8vPz8/T09PX19fb29vf3
9/j4+Pn5+fr6+vv7+/z8/P39/f7+/v///yH5BAEKAP8ALAAAAAAWABYAAAj+AP8JHEgwRgyC
CBMW3LTpoMKH/2IwZOgQ4kI2DL80tDhQ4p0+GTVWfCgREKGGEruIhCgRkaKGWc6kXJlQoiNH
Dd0Q0qRJIheaHTdRgtQQ0CNcwXKtkrgFaMRNOGNM+uSrm9Vru2hs2rIxaMNQorSpG5su3blp
WrsKlPgDlChs5s7JNUeO3LhvWkdG3Falb1+zd/DUETxP778q7qr4+QMIkLlyeCjVkXRHXpWE
VdpVIcS5EDlxd/7UcUMn3mWEVdhVMWSIUCFx4Ox0qdOFDrzTBKusq3Ko9x9w+WTt0sWL1Dvc
A6uoq4KoOSJv+USNmj6qG3KBVeCVuYQpU6Z57sIPi8d3/bDf8+j9clzPnmNAADs=}

image create photo fe_update -data {
R0lGODlhFgAWAOcAADtqqDtrqDdnpTVmpThopjpqpzdopjpqqHeaxaC726zG4q7I46jC3p25
2X6hyk16sDZnpTdnpjRlpFqDt7fN5bDI4qC82q3G4bfN5rrP5rvR57vQ57vR6K/H4W+VwThp
pnOYxUZ0rkVyrJ+52Ux4sDlppjdmpU56sYWmzbbN5bXM5abC4LHK5KO/3X+iy8PW6kNxrDtq
p1N+sz5tq0BvqzZnpDpppzprqH+kzLHJ45a325G02bTM5cja7EBuqjtrpzVlpE56tGKNw0x4
r6fA3a/J43Sfz83d7j1sqD9uq2yWyjpqqT5tqbTJ4pS22nKfz9Xi8DdopabA3cna7M3d7dTi
8Nzn8zZnpjRlpTlppzhopzZmpTVlpdrl8eDp8+Dp9OHq9Nnk8FV+szVmpOLr9aC+3qG+3dvm
8n+gx0FwrOPs9Zu63L3S6Nzm8lB8smWOxEd2sDxsqDRmpOTs9crb7K7I4sHV6oKjyzdopz5u
qz1sqUd0ruXt9sDS5tjj8dHf7qrG4sDU6bjN5YSkzGqQv1B7sj1rqEBuqVeBtZOy1sXV6Dlo
pjtppoelysjY6bDJ5LPK5KrE4Zq42j9vqURxqjxpo2qOvJSx07LJ4rbN5qK+3XKXwy9ZjzNl
pDFbkTZlojZno0FuqDdnpDZmpDRfl///////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////////yH5BAEKAP8ALAAAAAAWABYAAAj+AP8JHEiwoMGD
CBMWBBBAwAACBQwYHGCwwAEECRQsYNDAwQMIAyNIKFhgAoUKFi5gyKBhA4cOHj5EABGioIgR
JCKUMAHhBIoUKlawaOHiBQyCMWTEmEGjxkAbN3Dk0LGDRw8fBH8ACSLEhsEPQ4gUMXIECUEb
SZT8W3KQSRMnT6B4HShAYRQpU6hUsXJFIUEsEm5k0WLgChaCA7YoXszF78ABXbx8ARNGjMIx
BIGQKWPmDBqJBW8ITAMAsZo1bNq4yWLQwBs4EuIQlDOHTh07Vu7gASlwQB49MPYUlMOnj58/
gAIJGkSokKFDiFwkIlAQgqJFjBo5osBDxSMWkBYmRJI0yeAYSgMrWbqEiU2mHJo2leBksJNB
T59AhRI1ipTj/wD6FRAAOw==}

image create photo fe_configure -data {
R0lGODlhFgAWAMYAAH9/f+rp6Pn5+NjY1/j39vPy8YKXsjRlpOzq6P///050pHx8fLu7u+3r
6szMzK+vr2WErOjn5Orq6q2trePj4vr6+Xl4dNzc3JmZmejn5vLx7+3r6evp5/r6+oeHh8/N
yvj49/n59/n49/7+/p6enrW1tfb29Z+fnvj4+Ofm5LvByEVxqfT09J2wyt/f31l9q6enpiBK
h1R8rqSttvv7+3WQrqS60JCmvqexvcHBwePi4dPf6qKuvJ22zmN7lYScttfi7Y2YpZ240mB3
kZmtw9/n8IGTqVhthFtxiYaGhqG0yO7z9mB2j+Tj4V9fXpGmvvD095eltgAAALDG2+3y9oGK
lWyFocDR4v//////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////yH5BAEKAH8ALAAAAAAWABYAAAfygH+CggAAg4eIiX8AAQID
hoqRhAQFj5EGB5EACAKQiAcJCpl/C4WCDA2diaAODxCEERIAExQIFRarFw+jfxgZGhsIHMOq
gwcdB7yCHh8gAiECwyKQByPKhySFACUCwiYnByjXkgACKSorLOOSiy0HLi8w7Icx9QcsMjM0
npIxNTY3YhzAkUPHCH6J/O3g0cNHDAAjhh2MFOMHkCA+hAyJsWiEsImIYhApYuSIkBpIOHaU
mISekiVGmJxMeQhiEycgYzyBEkUmSpWCpAgdKvRPjClUqswEGpToUKNWhFx5QjORUymDYlix
4lAS0ZD15hUVFAgAOw==}

image create photo fe_folder_link -data {
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAACXBIWXMAAA7EAAAOxAGVKw4bAAABbElEQVQoz5WSPSwDcRyGnzvtibaKlDRRQVREF5MuRomNyccqMVg0
ImI1mAxU4msWg8XaRhgkJgwMpENTBh9tqr6ql9L2rv3XTs/Vu/7ePHnzyyOVov4VYB6Q+RlN25Xvr065pXIkYtIcJwBSKeov80fkxANcp4wLEiPSHGEZkwh3K9RYjAtl
PFUtAhBPebPKlumiKhOw/HXVRAfR7Djqc56+pkMc1ojxL40OGX2AYHybdLEFXSjMRJbIFXv+B0rmx1hLLDLqCvNebMRbH6G7Nkv8q796UEF0sZGcZsq9x/HHIA01KnfZ
Xp50Gw3WFIGrfVSt3xyk6j7alQw2+Y10ycancHCW9jHbGWIhOkOg4wCncvEL9OvZ9dYYj7oTSRKMu0IUhJ0WV471u2GWe3bw2EOVvazkUSI/wU5qkjYljVqqQ715IeDd
xKlcGgtuLKTMqzaEImdwvJ6YiiQDq4Co4DPNyhFOy7kZowwEvwF/CoUzZm0bGAAAAABJRU5ErkJggg==}

image create photo fe_file_link -data {
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAA7EAAAOxAGVKw4bAAABhElEQVQ4y6WTu0srQRSHvzVuZhIFXQw+8V4LEfHVK1oFQQTBSrS9
YOV/YX//gVvYXm20EATf2GgjIr5QC9EQRJP44sbZzUazt9GQNetG8FTnnDnzm++cmdF4s/HfGwezRn03Pjapks5Cwoympoc233NafnXmxLkerENI/VOBmsU4U89JNZc0
B1LTQ3sA5YUFqSdFz+q/fLzVLelqibhEwroWBuaBliKCs36D+H3arwtaGw1+riXgV4cGUMY3zdWCZWeJnmR9N5xHXlyxiyD36nyPoLpScjdiFBVZGRspggWZe2+CrP1C
Luem2L9I0rSSoGYx7klQNETLtPN+4uGZ6HGG2+FGAEwr498CgGXZCKnzpGyU/UrkMkbdEqx3CkJSlBZwHNg+umY0BpHLGMtjXYSDAWqNitJDfMdculKc9jXQzg/fzZ4C
ISn4o4VRO7csNAuqQsGvX2P+sfRWYWYkISFIpy2UspFSR9cDBMrLvAXGH24O23b48J0tz1MnHm92/775/wG+roQfoIxS/AAAAABJRU5ErkJggg==}

# Images for ttk::chooseDirectory

image create photo fe_dirclose -data {
R0lGODlhCQAJAKUAAFRWUlVXU1pcWP///1lbV2BiXt/i3Obo5O3u6/P08vj4911fW2NlYeHk
3+bp5Ovt6u/x7vDx72ZoZAAAAGNmYWpsZ93g2t7h2+Di3WdpZG1vatjb1dfb1Njb1Nfb09XZ
0WpsaHBybW1wa3N1cP//////////////////////////////////////////////////////
/////////////////////////////////////////////////////////yH5BAEKAD8ALAAA
AAAJAAkAAAY4QEBgSBwKBsjkgFAYGA6IhGKwYAwajgckMihIBpNweECpDCwXDOYyyGgGG07H
8xmAQsqkaMTv94MAOw==}

image create photo fe_diropen -data {
R0lGODlhCQAJAKUAAFRWUlVXU1pcWP///1lbV2BiXt/i3Obo5AAAAPP08vj4911fW2NlYeHk
3+bp5O/x7vDx72ZoZGNmYWpsZ93g2t7h2+Di3WdpZG1vatjb1dfb1Nfb09XZ0WpsaHBybW1w
a3N1cP//////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////yH5BAEKAD8ALAAA
AAAJAAkAAAY4QEBgSBwKBsjkgFAYGA6IhGKwYAwaDsQDMihEBohweCCZDCgVhKUyuGAGGQ1i
wxl0PMrkB8Tv94MAOw==}
##############End Image fsdialog#################################

  image create photo fe_upArrow -data {
    R0lGODlhDgAOAJEAANnZ2YCAgPz8/P///yH5BAEAAAAALAAAAAAOAA4AAAImhI+
  py+1LIsJHiBAh+BgmiEAJQITgW6DgUQIAECH4JN8IPqYuNxUAOw==}
  image create photo fe_downArrow -data {
    R0lGODlhDgAOAJEAANnZ2YCAgPz8/P///yH5BAEAAAAALAAAAAAOAA4AAAInhI+
  py+1I4ocQ/IgDEYIPgYJICUCE4F+YIBolEoKPEJKZmVJK6ZACADs=}

  image create photo fe_ru_24x16 -data {
    R0lGODlhGAAQAIQSAAA4pdUrHqkycnd/uHeAuHiBuXqCutt5edt6eb2Bmtx7et1+fd6Afs3Q49XX5vz8/P39/f7+/v//////////////////////////////////////
    /////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAB8ALAAAAAAYABAAAAVGoCSOZGmK0amq0OqS6ftCT23feG43fO//wB5gSCwaj8MBcrlUMp9EAnQ6
    EFiv2KzWmgh4v+Cw2HsYm82LsxpcXq/TbjUiBAA7
  }
  image create photo fe_usa_24x16 -data {
    R0lGODlhGAAQAMZ5ADk6azo6azo6bDo7bDs7bDs7bTs8bjw8bD4+b2A2ZLMhNLMhNbIjNmI5Z0RFckVFckZGdEdGcrIrPEdIckdIdLIsPEhJdElKdElKdUlKdkpLdkxM
    dUxNd01OeE5PeE9Qd1BQdlBRd1FRd1FSem1McFJUempPc1ZXe1hYfFhafV9fgF5ggWBhgWFhgWFigWRjhGRkhGVlhWZmhWtsiW1tinlrhXBviXhth3FyjntwiXN0jXp5
    kn16kHt8lH19lIOEmIWFmIeHmoiJnImJnIqKnouLn4uMn4yMn4yMoIyNoY2NnsV+g42NoI2NocZ+g8R/g42OoI2Oo4+PoI+PoY+QoZCQopCRoZGRo5GRpZOSppKTpJKT
    pZSUppSVpZWVp5aWqJaWqZaXqJiZp5mZq5maq5qbq5qbrJycrZydrp2drZ2erp2er56fsKCgstOorNGqrN/LzOPLzeTLzeXMzenR1Ojn6enn6fDn5/Hn5///////////
    /////////////////yH+OUNSRUFUT1I6IGdkLWpwZWcgdjEuMCAodXNpbmcgSUpHIEpQRUcgdjgwKSwgcXVhbGl0eSA9IDcwCgAsAAAAABgAEAAAB6GAJzMtJTQsLh87
    JBIVjY6Pjic+PkQ6P0BBOmJ0nJ2enjA+OzY9OD4zRkNwq6ytrRA2OkMzOzg/MzVOS7u8vbwvOzsyPjo7MT9teMrLzMwXsUEyPZY0ub7XuynFNrE6ODtic3Hj5OXkCDIu
    6TMrKjNAbm/y8/TzrG/3q277/P39casABoRjrmA5bAgTNlvIcGHCh75cSZwo0aDFi5AyaswYCAA7
  }

  image create photo fe_eye_hidden -data {
R0lGODlhFgAWAKUlADZATVJbZlpxkVlykn+l2IOt5YOu5YOu55Gx2qOwwoq174u3
8JvB8qnB4arC4avC4bfL5cjPvsjQv9XUu+DawcHh79Pf7sHl+NXg7tXg78Lm+sHn
/sLn/cLo/+ft9u3y+ff17fj27vT3+vX3+/z69v//////////////////////////
////////////////////////////////////////////////////////////////
/////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAAFgAWAAAG1kCO
cEgsGo/IpHLZaTo7HI10ynlan5eKhMKlSCqX63OjxXgsEAgG5K1sxJoKBYR5MBie
0ejDrmisGhAUIR4OCgcIHiUjFh4hXn9NGhYYJCIVBwYEAwkQFQwVIyQYFlUcciQl
Hg0HBAEAAAIECg2KoxVRESAlJRkMCgSwsLMMGbwgEhqnFKmrra8AAQQHtSUkFLgd
k5WXmZsDBAYGodfZkluErAoFBYe1j8mAcnR2CwsMD2vYkVdaFGdpGrURg0XLBC4T
voQh+CTKFClVriyZSLGixYtHggAAOw==
  }
  image create photo fe_hiddencb -data {
R0lGODlhFgAWAKUlADZATVJbZlpxkVlykn+l2IOt5YOu5YOu55Gx2qOwwoq174u3
8JvB8qnB4arC4avC4bfL5cjPvsjQv9XUu+DawcHh79Pf7sHl+NXg7tXg78Lm+sHn
/sLn/cLo/+ft9u3y+ff17fj27vT3+vX3+/z69v//////////////////////////
////////////////////////////////////////////////////////////////
/////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAAFgAWAAAG1kCO
cEgsGo/IpHLZaTo7HI10ynlan5eKhMKlSCqX63OjxXgsEAgG5K1sxJoKBYR5MBie
0ejDrmisGhAUIR4OCgcIHiUjFh4hXn9NGhYYJCIVBwYEAwkQFQwVIyQYFlUcciQl
Hg0HBAEAAAIECg2KoxVRESAlJRkMCgSwsLMMGbwgEhqnFKmrra8AAQQHtSUkFLgd
k5WXmZsDBAYGodfZkluErAoFBYe1j8mAcnR2CwsMD2vYkVdaFGdpGrURg0XLBC4T
voQh+CTKFClVriyZSLGixYtHggAAOw==
  }
  image create photo eye_nohidden -data {
R0lGODlhFgAWAMZpAP4AAP8AAP4BAv0DBP4DBI0kLIMnL5UiKYslLP4GB/8GBv0IB/4JCvwLCvwNDvsQEvoRE/kWGPkXGfgbHvYhJPYiJfQrMPMsMVJbZvMuM5hHWvMv
NPE1O/E3PPA6P+8+RO4/RcFQaO1GTexHTsRTb1lykrxXcvRMQ9NUaepPV/NUSvZdYPVmasJ0gLF4nsSInn+l2IOt5YOu5YOu55Gx2oq07oq17+ihjou38OenlM+wv5vB
8s23xqnB4arC4avC4c67zf+ysszA0s3A0/i1uMvF2LfL5cvG2cjPvsnM38jQv8jQ5MjR5dXUu8fW6sbZ7sXb8cLd6sLe7MXe9ODawcHg7sHh78Th99Pf7sPj+sHl+NXg
7tXg78Lm+sHn/sLn/cLo/+ft9vjz6/j07Pf17fj27vT3+vX3+/z69v//////////////////////////////////////////////////////////////////////////
/////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAWABYAAAf+gF+Cg4SFhEsWHoaLhUkUARyMkkUTARtOYJmaYF9dnp9fYEMRAR1Qm5pa
VkpUrVRKVjwPASBTqGBeq1thWEZGW2Q5DQEjV7ddVlRkWz87O2FnRAwBJ1FdqF1GVGVhPjYzNGFBCgErYq/XmV1YW2hmVjMyMCUtBAEoVWdoW1ihX8lo0oTpMQMGBgMA
AoSo0SNMmn1WOiEhkyYNlx02YBQIEOAADBs7uFQko6TLPyoBB84wwREBBhgzGj6kEhHMunZmqpAIIEBDCRgyZFjRRzOUOlZjWAQY4CJGjG8Ny6DDJkVFgAQvduDAseMH
MJrpNmVJEWDBDV6+sIR5ZeUWmCsxIgI40LGqSasmsLS4nfIhAAQgnD6BcvuEQwAJQiQxyhBgwhHFjAJUSAKZ0QUmlRkFAgA7
  }

  image create photo fe_icontools -data {
    R0lGODlhGAAQAOeYAFVve1ZwfFt1gV53g194hGB5hGB5hWd9h26GknGHknWHkXOMmHSMmHaOmneOmnmQnHqRnXqSnXuSnXySnn2Tn4yaopKfpY6gqvuNAPuPAPuQAJCk
    rpCkr5GkrvuRC/WRKPuRE/uRFZGlr/uSDZilrKeioJOnsZaospapsrGjmJmpspiqtJqstZ2ttKGts56uuKKvtKWvtKCxuaOxuKS0vKW0vKW1vPqmOP+mJ6a1vaW2vf+n
    KKa2vqe2vqe3vq67w7O6vq69w6++xP+wSv+wTa+/xbC/xf+xT7K/xf+xVbHAxrLAxrTBx/+0XLfEybjEyrnFy7rFzLvGzLzGy7vHzL/Izb7JzsHL0MLM0MLM0cTM0cTO
    08fP1cjP08nQ1cvR1MrS1s3S1s3U2NDX29HY3NPY3NPZ3NLa3dTa3Nne4drg49vg493h4t3j5f7dwf3dyd/k5uLm6eTo6uXp6+bp6v3k1v3l1+jq7Ojr7enr7P3n2f3o
    2+rt7urt7/7p2+vu7+zv8O3v8e3w8e/y8/Dy8/Dz9PL09fP19f306/T29/706//17Pb3+P/27vj5+fr6+/r7+/v8/P78+vz9/f39/f7+/f7+/v/+/v//////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAAGAAQAAAI/gAxCbREEFCcPpPwTLlAQUUagZgsUYII0RKmQU6KFKHSRcsMChAeeKlIcaDASGqEGDkj
    EE4DCBHCmCxZySKmQ0GKRBHIaAEEA0BmUlzDR+AWJUWuCKwioUAABWjMTCwpZgMULh16LFFaZgIBAAEEOIDwpSSmQiZEqN0gwwcWBgMqsIkBAEECOmYp9fnxokYODjyW
    tLDwCBMJAAfu2DSLKRImRCk26FiSBRImRy7yYJpKkaDARk1ulNhgQ4kVRhU5V7TYiMiOER9gkFbyxNDAxasXHdnhIUOdRCw20FDCJFBE1QIpKUqCwwMGOwIJoRA+5omg
    iGYlDWkeQg/FPyekImBqc8ZzSUtuNIDYY1bOCjJI5jDG/sYPwfsWL+EBAyfi4oAAOw==
  }

  image create photo fe_icondirdenied -data {
iVBORw0KGgoAAAANSUhEUgAAABQAAAARCAYAAADdRIy+AAABi2lDQ1BHSU1QIGJ1aWx0LWluIHNSR0IAACiRfZE9SMNAHMVfU7UilQ52EOmQoTpZKCriqFUoQoVQK7Tq
YHLpFzRpSFJcHAXXgoMfi1UHF2ddHVwFQfADxNHJSdFFSvxfUmgR68FxP97de9y9A4RGhWlWTxzQdNtMJxNiNrcqBl7RhwhCiEOQmWXMSVIKXcfXPXx8vYvxrO7n/hyD
at5igE8knmWGaRNvEE9v2gbnfeIwK8kq8TnxuEkXJH7kuuLxG+eiywLPDJuZ9DxxmFgsdrDSwaxkasRTxFFV0ylfyHqsct7irFVqrHVP/sJgXl9Z5jrNCJJYxBIkiFBQ
QxkV2IjRqpNiIU37iS7+EdcvkUshVxmMHAuoQoPs+sH/4He3VmFywksKJoDeF8f5GAUCu0Cz7jjfx47TPAH8z8CV3vZXG8DMJ+n1thY9AkLbwMV1W1P2gMsdYPjJkE3Z
lfw0hUIBeD+jb8oBQ7fAwJrXW2sfpw9AhrpK3QAHh8BYkbLXu7y7v7O3f8+0+vsBZvhyovthgiQAAAAJcEhZcwAALiMAAC4jAXilP3YAAAAddEVYdERlc2NyaXB0aW9u
AENyZWF0ZWQgd2l0aCBHSU1QA65fWgAAA11JREFUOI11lL2LnVUQh5+Zc96vvXf33k1MSJYQVIQgokQLm4BpNJBCOy1Ey9joH5Pa0hSCVoaAQSQQEcQPsIoYYgjEwCaS
vdm79/N933NmLK6t00z5Y37Pw8i3N7/zu3fv0vcZMyfGCIC7A87L517g0uVLiCoQUFcEcByjJ3jJqusIdYkA8ftbt7l//wGgmBkqESfj7qgqv/36O29ffhdxI4oiDgAC
BFVYtDRNRe4THoSYsoAUxFhgZuCKeUJFUFWeTluuXv2cdj1lPBwyn82oqwYU+rRiPag4tbvLlQ8/AkvEGCNlWVIU5eZM180WQ1UZH9/jjzt/0q0OiYWisaTtEl1O1HXN
wg1ZzPnk/Y/JKRMlCgTDJOMIovZfh5BJHDzdZ7upKIqCHiNlSKFie+c4i+khp/MApCDNjDhqiEEcxRDPeAZRRURwd5zMcBAgdSCChIpV29E0FWk5p0odT7aVfrVkNQxs
C0R3ARQhbNi5IKJABldyzpQayFlI5uwMR9hyRtOtOX92j8nIeTTJrPyIYFtETFAvUAKOgQPGJsCNLGBELBuhLMjtmjonPnjnLaqjZzx/5yG88TqDgwPYG6JmCcTIOSMi
FEWx0UJAVbG6I7eB5wplQUfnysUL5zlz50vGHOOvN1/j8f49ll9fZ8sMFRFENlTNMin1pNRjvgkKCwih4O88ZdAox4vAqbmz2474YTXj2u2feTbaY3nvFyZ5TZQAGgNu
gqujGlAc0Q2gptzGOoFBwXL6DM8NJ83Ic+FRkVhuDVgeO439dI9Dgdj3mdQboIAgslHGDHLOdNZSEwgtVDtjUqyo9wr2D4RXzo15dXyCSnsGJ19itgzEGGpCKDBz3ASV
SFBB1Mk54wNlvWgZhyGraeK9ixcob37FKD7h7De3+KeekJjji5p84wuiYAgG5lg2Eoa7EwiIO/W6JZclk3ZFrmqWtTLaMR7IkjPLh+xOW5rtksfVDtXEiOvllNQtAMGz
k20jNRZAjHnXUeqcciuSrWXSHRL7OeNim7AVSH1B2UXwx5SuxE8/u8Lh4RFlWeImwKa7EAKizlQiZ1LFZHnAsGrYH0W6H68x8gFH3tM2W/iBcfLEPrMgiG8e3/+PQdJE
RCErC+t5ev0G+IJgEdGMZSVQYS+e5l9h+80+zAmm+gAAAABJRU5ErkJggg==
  }
  image create photo fe_icondir -data {
    iVBORw0KGgoAAAANSUhEUgAAABIAAAAQCAYAAAAbBi9cAAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4wYXCDgNebfI9AAAAgZJ
    REFUOMuNkz9PFUEUxX/3zuxbQAlSkGhhaWEwRhNbY6Extmhi7Kz5CH4P/RZY2FnYEG20sKOSaExEBNTn44+P3Tdzr8U8Hw8k4G0mszvn5PzO7MrrO/PcfLXCSfPm3pXr
    9bnwLtQS8SMvFZqttCwAbxeuznY/9BfcCQcnisL3SDPzE4/mF8/f7cxViEp5bg6tE6ciK0/XiADd1f7Da08uPtOACoK7I5WgAFGQCZE4HQ6Fsex4MthLuHkxcqeuJlVj
    LSK1IB1BRJApxRsjnlXcIXrA1BGHrJABQkkYAVK3az64gHcEiQEUpFLUgQ5IE1B1jIRkcBfwDA4SO2AQt148eD59+fYNjb8LvgqFCeRIqYfqc8j9lv7Hl0gUos7N3a8v
    LY6dEP53rPeN9v3SAVqZ3eFWjokwFgMbWw0VGTfKuPdAAhBOSZYYadgGP2S0A/KjiD2AnIDnBmLFUH7hB7dmwAbwtRhJOAZr1ApIGqZNwC4iERgQsQxs4qwNseQELB8Z
    iifE+5AFHCJmwHfUNgDFVE8xy6g5WAJaDMXxv2hdaDYhhvIRov/6+BANIDlYhpRHNUSJWjaxLSVbUbkabo7j5Uc1QV2LLghEJ2TDg2KND+L+6pfl9fWlW4PeLm030/40
    9rcb0p7R9MCahJ6pqCedaiZQz1R0ZiOdWSVMKe3nwafBjj3+A1B95HRZw8dhAAAAAElFTkSuQmCC
  }
  image create photo fe_icondirup -data {
    R0lGODlhEAAQAKUAABJNbwoSHxVUdIGeuhdYeggeMRlKat3v+BOQtBVWeAcXKBtLav38/VnD2jzX4RVaehtPb3HR4Bmzzg6gxUjf6RKQtRNUdgcYKhJMbeLw+Q6Xvxyi
    wxBTdQYQHSA3TwEDBAAAABFHYJ3e7iK60RWavA9dfgABAc3r9hGXuUPV3iKUsQomO/36/SqYswonOyzH1ReOrIDC21isxRSDnwoZKQgcLQccLP//////////////////
    /////////////////yH5BAEKAD8ALAAAAAAQABAAAAZiwJ9wSCwaj8ghIJAkCgaEQvNnGBwQCUVyMWA0HIiH1gjpRiQTSsVyKWIGmYZEo5k4NpzOkOP5gEIiGiMkJSYg
    h0YcJygpKitNHCyMLS6Qiy8wlUkcMTIjMyCQNDU2iFOnqEEAOw==
  }

  image create photo fe_iconfile -data {
    R0lGODlhEAAQAKU7AACFvQCGvQCGvwCHvQCHvwCQyACU0gCU1ACU1wCW1ACW1wCY2ACZ1wCb1QCb3QCc1gCc2ACc2gCd2wCe1gCe2ACg1wCo6ACp7ACu7gCu8ACv7wCv
    8gCw8ACw8zep2Dqp2C+35DG55jO86DO86kPC8nC31HC31nO31Ha31na51nO61nO613O62UHH92682Xa61na62UTH93m62TrR/3nH5oXO7YfY94XZ+Yfb+4rb+4re++/w
    8e/w8e/w8e/w8e/w8SH+SUNvcHlyaWdodCBJTkNPUlMgR21iSCAod3d3Lmljb25leHBlcmllbmNlLmNvbSkgLSBVbmxpY2Vuc2VkIHByZXZpZXcgaW1hZ2UAIfkEAQoA
    PwAsAAAAABAAEAAABo3A369BgRiND6FSSYnpnrEOJbRUTjiZbLYjAlV/kxZu3MpwZiPqMjzGtTgczEIQWGO1nE3EoACsYzmBgTQnMB8DdngWBgcHCYhWYmM2KyYqLB6Q
    Qmw4Ny4lKpeZdhwaEoyNjppggDUnL7AvhqtXF6ipqksUJCkoMri5ShUOBwgICsjIDARLBQAE0NHSQkEAOw==
  }
  image create photo fe_iconfiledenied -data {
    R0lGODlhEAAQAMZNAO0AAPEAAPADA/MSEs8fH/IWFs0uLtgvMOA2NuE3N986ROE9Pp9QYMdMekF52N9ZdOxbXEeD6FCC1VGC1UaE6+5cXkKF9EOG9ESG9EWH9EaI9EeI
    9EiJ9EmJ80mJ9Npmi0qK9J50xkuL9EyL9FGL602M9E6M9E+N9FKP9KN7y9twklaS9FeS9P2Agf+Bgf+CgnWk83al8/+FhXqo832p86mg3OaWloOt856n55K389Wsytas
    yJ6+8qC+8p+/8qC/8te0tO+wt6LD+e2zs6bF+q3H8uC8vOjFxe/IyNbU1OPc3O7o6Pjy8v//////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAQABAAAAeNgH+Cg4SFhCeIiSw/hoImj5ArRIyGJZaXKEJEPYYjnp8jJBMShiKmp6YR
    DoYgra6uFIYeHjxFtkU8Hh2GOkE7ODfBMxwchRUyLi8tNTQ0MBsbhQABAwUCDz4+ORoahARDTEtKSQcxGecZhAY2SEdGQA0Y8vKFCwgICQohF/z8hQwqIHxIYaGgwUYI
    CQUCADs=
  }
  image create photo fe_addfile -data {
R0lGODlhFgAWAKUwAHS37nK48H256oe4342325K33JK41pa40ni/+Hq/95+5znzB+H/C+IHC+LS6tLe6r4XE+IbF+IjG+IjG+ca7oYrH+Y3J+dW9io/K+ZDK+ZHL+eO+
bfS/NvXANZbN+fbAM/jAM/vAKPrALfvAK/vALZfO+ZjO+aHS+q7Y+7Xc+7fd+7jd+8ro/Mvo/M7q/eH1/v//////////////////////////////////////////////
/////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAD8ALAAAAAAWABYAAAZ+wJ9wSCwai5mkUqk5IpdKTMrkHEKjLlap+rsmMa5Xy1P1ZsAvMflozqBW
K9XJ2YbS68o7PqPH99sSf1ATFQ0AgkoWAQUHG4hJEAYcHySVRl4YCQMXlZ0kT1cLDiOenURmEwQdpZ+nXggPIaytQmYMAhQipaBXEQognlxVtD9BADs=
}
  image create photo fe_adddir -data {
R0lGODlhFgAWAMZeAAqERACIRQqFRQuJRwyJSAyKSAWNSQCRSgqOSw+OSwWSTQiSTRKSTwKXUgaWUCeNSAuWURSXUxacVhecVhecVziUWxKgWRigWhqgWjiYThakXByk
XS+fVRulXhylXh2lXkKaYhaqYR6pYTuhZEGiZ0SjaDGsXkKmajSsX1CqWtGPAF6qec6RHc6SH9uYAJWoSYivVNWcJ9mcHYm0VuWhAN7BRe3CNuDFRuDFSezDO+7FPP3E
LOzHSv7FLf7GMO7JSu/JSf7HMf7INfrJOv7KOffLV/7LPv7MQ/rNSPzNSP7OR/nOXP/PTP/RUMXZzP/SVf7TXP/TWcbbzP/UXf/VXv/WYv/WZv/XZ9vo39vq4PD08fD1
8vH18v3+/f//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////yH+EUNyZWF0ZWQgd2l0aCBHSU1QACH5BAEKAH8ALAAAAAAWABYAAAfhgH+Cg4SFhoeIiYqLgjSOj46Mfy6UlZaMKpmamjJLV5+gV1aDLC2mpy0x
RVWsra6CUFSys7JTtre4U4JRvL2+v7+CT8PExcbGgk3Ky8zNzYJM0dLT1NSCStjZ2tpIPzxASUqCR+Tl5uU4MBwNGS81gkbx8vPxNykXExAMCA+CRP8AAxIZMqMDBhJY
FCQgIOCPkIcQIwrRgcLDiRVbQFQYAOCPjyAgQ4rMEUJDFi5dtDgJ0PHPjh4wY8a0YeKDhRJaDhgg0HKRiA8YRkhZsFCSoA0YJDhgkKCAUUEYKERgMCgQADs=
}

image create photo fe_iconview -data {
iVBORw0KGgoAAAANSUhEUgAAACsAAAAtCAIAAAC4ZgWKAAAACXBIWXMAAA7EAAAOxAGVKw4bAAADc0lEQVRYhe1Ya0hTYRh+znbsdHY281Ze1pWcWzdySpaptMpuDH9N
MCIKIUijMAgiIsIfURT0qwsFQSGFjaD+JHbP/NGsdKgt3Zw10rVsZk7ntjaPrR8Humxr023Ofuz5853zve9534eX53t5z0d4vV7MKEhuOXhco9MPRz36SlnyxdOFwX14
3DId6ScZljcdiaeEOAOA4M7CExM7TQlKl5DBHWa+BnEG/wODwDLZc6UbQF3Vsl/Pkwf31eQx8zWIn8a4DoC4DoDIdZC7SFRdmkUn8CbGPabOln691jZocTvslEAoSk0X
56xen75BIBBMmcEkkbtQWLNdzCcIs6G99UG9c/T3ROQaG3GNjVg/9hzTNFZUVBQVFf0rSBR0YHj9rO2RGl5vqniJtGDTvEU5swUij8th7e/tbWseMHUDUCqVKpVqWhh8
Mna+UF8CkFdaLl1bShCEj8OwoeXx3TqWZSsrK0tKSvwjhKmDzKRZZ3cunWDHWxvr4fXmblbJ1m0JGCpZum5bOa/h9jW1Wp2Xl8cwjI9DmGehUDIHQN+7VsfIUHLGguWF
W4M4z5EUyJavcjqdTU1N/tbANfizrwXpceaedgCSfAX8iu8DacFGfddbrVarVCp9TBH1g5FBC4B5CyUhPZmsbAAWi8XfFKYOru+X8QnC7XQAoBhhaLL82SRJut1ulmVJ
8q+kYdbA6Z4AQAkYAG7HWEh/gnWxLEtRlE96RKiDxLlZo0NfrH3GxLSM4Azsll4AYrHY3xSRDubnrAZgbGtCqB9ww5vnAORyeZQZLF5ZwCSlDg/0d2keBnGzGV8ZunQM
wygUiigz4PHJNTt2gSDan93r1jwKeBXxTf/y4Z0bAMrKyvzbEQB+bW0tgA+2H+GREKWkU7TQ8l438KHrc6+OT5IUzfDJhO+O0c/vda0P6jtePuWYWa3W/Px8mqZ9IkRn
Qvlk7HzTcMtpD3BbIBQKVSpVc3OzyWQiaebI4RqpJDsAg8jh8Xg0Go1WqzWbzXa7nWGYzMxMuVxeXFxM07TL5Tp+srZF10MlkFfPn/mTRNQYhMTXoW+7qw7Z7A4qgbx8
7tSKZTJuP3ZTWlpqys0rF5JEjHucPXD0xLtuPbcfuxpwsA5+3VNdYxtzpCUl3r9dBwDemOOLdbB8776OtzruNdY18MfMT+txBv8Dg589dO4PXNeoRAAAAABJRU5ErkJg
gg==}

  proc readName ent {
    global widget
    global yespas
    global pass
    set pass [$ent get]
    $ent delete 0 end
    set yespas "yes"
  }

proc propfile {obj} {
    if {[file  exist $obj] == 0 } {
	return
    }
    if {[catch {exec stat $obj} upfile]} {
	unset upfile
	file stat $obj pfile
    }
    if {[winfo exist .feprop]} {
	destroy .feprop
    }
    toplevel .feprop -bg cyan 
    wm geometry .feprop 408x168
    wm iconphoto .feprop fe_iconview
    wm title .feprop "Свойства [file tail $obj]"
    set lbut [list]
    set row 0
    set bb 0
    set b0 [cbutton new .feprop.frame -type frame -strokewidth 0 -stroke "" -rx 0 ]
    set wcan [$b0 canvas]
    pack $wcan -fill both -expand 1
    lappend lbut $b0
    set g4 [$wcan gradient create linear -method pad -units bbox -stops { { 0.00 #ffffff 1} { 1.00 #dbdbdb 1}} -lineartransition {0.00 0.00 0.00 1.00} ]
    $b0 config -fillnormal $g4
    update
    wm geometry .feprop 410x170+100+100
    wm minsize .feprop 410 170
    eval "bind .feprop <Destroy> {bind .feprop <Destroy> {}; foreach oo [list $lbut] {\$oo destroy}; destroy .feprop}"
    foreach {x1 y1 x2 y2} [$wcan bbox "[$b0 move 0 0] rect"] {break}
    set x0 [expr {($x1 + $x2) / 2}]
    if {[lsearch [font names] "font_titul"]} {
	font create font_titul -family {Nimbus Sans Narrow} -size 15
	font create font_prop -family {Nimbus Sans Narrow} -size 11
	font create font_propb -family {Nimbus Sans Narrow} -size 11 -weight bold
    }
    if {[info exist upfile]} {
	set ll [split $upfile "\n"]
	set bb [$wcan create text 2 10 -anchor nw -text  "Объект:  $obj" -fill black -font font_propb]

	foreach {x_1 y_1 x2 y2} [$wcan bbox $bb] {break}
	set ys [expr {$y2 + 4}]
	set upfile [join [lrange $ll 1 end] "\n"]
	set bb1 [$wcan create text 2 $ys -anchor nw -text  $upfile -fill black -font font_prop]
	foreach {x0 y0 x1 y1} [$wcan bbox $bb $bb1] {
	    wm geometry [winfo toplevel $wcan] [expr {$x1 - $x0 + 2}]x[expr {$y1 - $y0}]
	}
	foreach {xb0 yb0 xb1 yb1} [$wcan bbox $bb1] {
	    if {[expr {$x1 - $x0}] > [expr {$xb1 - $xb0}] } {
		$wcan move $bb1 [expr {(($x1 - $x0) - ($xb1 - $xb0)) / 2.0 }] 0
	    } else {
		$wcan move $bb [expr {(($xb1 - $xb0) - ($x2 - $x_1)) / 2.0 }] 0
	    }
	}
	wm resizable [winfo toplevel $wcan] 0 0
	return 
    }
    $wcan create text $x0 10 -anchor c -text "Сведения" -fill black -font font_titul
    incr x0
	$wcan create text $x0 11 -anchor c -text "Сведения" -fill gray70 -font font_titul -tag id_text0
    incr x0 -1

    set delta 12
    foreach {xz0 yz0 xz1 yz1} [$wcan bbox id_text0] {break}
    set yt [expr {$yz1 + $delta}]

    $wcan create text $x0 $yt -anchor c -text  "Объект:  $obj" -fill black -font font_propb
    incr yt 15
    set row 0
    set x0w [expr {$x0 + 4}]
    set x0e [expr {$x0 - 4}]
    foreach {prop txt} [list atime "Дата доступа:"  mtime "Дата модификации:" ctime "Дата изменения:" size "Размер:"] {
	$wcan create text $x0e $yt -anchor e -text  $txt -fill black -font font_prop
	if {$row < 3} {
	    $wcan create text $x0w $yt -anchor w -text  [clock format $pfile([set prop])] -fill black -font font_prop -tag id_text1
	} else {
	    $wcan create text $x0w $yt -anchor w -text  $pfile([set prop]) -fill black -font font_prop -tag id_text1
	}
	incr yt 15
	incr row
    }
    if {[tk windowingsystem] == "win32"} {
	set tc "\x02UTC"
	set tekpwd [file dirname $obj]
    	set wobj [string map {"/" "\\"} $obj]
#    	set wobj [encoding convertfrom cp1251 "$wobj"]
	set oldpwd [pwd]
	cd $tekpwd
	if {![catch {exec cmd.exe /c dir $tc $wobj} stfile]} {
	    set DirList [split $stfile \n]
	    set FileCrTime [clock scan [string range [lindex $DirList 8] 0 20] -format "%d.%m.%Y %H:%M" ]
	    $wcan create text $x0e $yt -anchor e -text  "Дата создания" -fill black -font font_prop
	    $wcan create text $x0w $yt -anchor w -text  [clock format $FileCrTime] -fill black -font font_prop -tag id_text1
	}
	cd $oldpwd
    }
}


  #Увеличить/уменьшить картинку (отрицательное значение - уменьшение)
  proc scaleImage {im xfactor {yfactor 0}} {
    set mode -subsample

    if {$xfactor>=0 && $yfactor>=0} {
      set mode -zoom
    } else {
      set xfactor [expr $xfactor * -1]
    }

    if {$yfactor == 0} {set yfactor $xfactor}
    set t [image create photo]
    $t copy $im
    $im blank
    $im copy $t -shrink $mode $xfactor $yfactor
    image delete $t
  }

  #Считываем размеры экрана в пикселях
  set ::scrwidth [winfo screenwidth .]
  set ::scrheight [winfo screenheight .]
  #Считываем размеры экрана в миллиметрах
  set ::scrwidthmm [winfo screenmmwidth .]
  set ::scrheightmm [winfo screenmmheight .]
  #Запоминаем сколько пикселей в 1 мм
  set ::px2mm [winfo fpixels . 1m]
  #Запоминаем сколько целых пикселей в 1 мм
  set aa [expr $::px2mm + 0.5]
  set ::intpx2mm [expr {int($aa)}]
  #Проверяем, что это телефон
  set ::typetlf 0
  if {$::scrwidth < $::scrheight} {
    ttk::style configure TCombobox -arrowsize [expr 5 * $::px2mm]
    set ::typetlf 1
  } else {
    #Конфигурирование виджета под смартфон
    #Ширина 75 mm
#    set ::scrwidth [expr {int(75 * $px2mm)}]
    #Высота 160 mm
#    set ::scrheight [expr int(160 * $px2mm)]
  }

  set upz 1
  if { $::px2mm > 15} {
    set upz 4
  } elseif { $::px2mm > 10} {
    set upz 3
  } elseif { $::px2mm > 5} {
    set upz 2
  }
#Масштабируем иконки с учетом разрешения
  if {$upz > 1} {
    foreach nn [image names] {
	if {[string range $nn 0 2] == "fe_"} {
	    scaleImage $nn $upz
	}
    }
  }

  set ha [image height fe_iconfile]
  #Высота строк в treeview
  ttk::style configure Treeview  -rowheight [expr $ha + 2]
#Стиль заголовка
set fsize [winfo pixels . 2m]
switch -- $::tcl_platform(platform) {
  "windows"        {
    set svgFont "Arial Narrow"
  }
  "unix" - default {
    if {[string range $::tcl_platform(machine) 0 2] != "arm"} {
	set svgFont "Nimbus Sans Narrow"
    } else {
#	set svgFont "Roboto"
	set svgFont "Nimbus Sans Narrow"
    }

  }
}


font create fontfe -size $fsize -family "$svgFont"
ttk::style configure Treeview.Heading -font TkTextFont -background "#bbf9fe" -padding {0 0.5m 0 0.5m}
ttk::style configure Treeview.Item -padding {-4m 0 0 0}

  proc filedel {w file typefb} {
    set answer [tk_messageBox -title "Удаление папки/файла" -icon question -message "Вы действительно\nхотите уничтожить\n$file ?" -type yesno -parent $w]
    if {$answer != "yes"} {
      return
    }
#    file delete -force "$file"
    file delete -force [lindex $file 0]
    set ::FE::folder(initialfile) ""
    populateRoots "$w" "$::tekPATH" $typefb
#Или goupdate
    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
  }


  proc trace_columns {name index op} {
    ::FE::detailedview $::FE::folder(w)
  }

  proc normpath {d} {
	set TPtemp $d
	set i 0
	set len [string length $TPtemp]
	set dpath ""
	while {$i < $len} {
	    set ss [string range $TPtemp $i $i]
	    if {$ss == ","} {
		append dpath " "
	    } elseif {$ss == "-"} {
		append dpath "  $ss"
	    } elseif {$ss == "\\"} {
		append dpath "  "
	    } elseif {[string is alpha $ss]} {
		append dpath " $ss "
	    } else {
		append dpath "$ss"
	    }
	    incr i
	}
    return "$dpath"
  }
  
  proc showContextMenu {w x y rootx rooty fm typefb {mtype 0}} {
    set padddir1 "M 2 2 L 2 14 L 9 14 L 9 13 L 3 13 L 3 8 L 5 8 L 6.9980469 6 L 13 6 L 13 9 L 14 9 L 14 4 L 9.0078125 4 L 7.0078125 2 L 7 2.0078125 L 7 2 L 2 2 Z"
    set padddir2 "M 11 9 L 11 11 L 9 11 L 9 12 L 11 12 L 11 14 L 12 14 L 12 12 L 14 12 L 14 11 L 12 11 L 12 9 L 11 9 Z"
    set pdeldir1 "M 2 2 L 2 14 L 9 14 L 9 13 L 3 13 L 3 8 L 5 8 L 6.9980469 6 L 13 6 L 13 9 L 14 9 L 14 4 L 9.0078125 4 L 7.0078125 2 L 7 2.0078125 L 7 2 L 2 2 Z"
    set pdeldir2 "M 11 11 L 11 11 L 9 11 L 9 12 L 14 12 L 14 11 L 12 11 L 11 11 Z"
    set paddfile1 "M 3.0 11.4375 L 3.0 3.0 L 7.4296875 3.0 L 11.8330078125 3.0 L 14.28515625 5.4521484375 L 16.7109375 7.8779296875 L 16.7109375 9.6708984375 
	L 16.7109375 11.4375 L 15.65625 11.4375 L 14.6279296875 11.4375 L 14.548828125 9.9345703125 L 14.4697265625 8.4052734375 
	L 12.966796875 8.326171875 L 11.4638671875 8.2470703125 L 11.384765625 6.744140625 L 11.3056640625 5.2412109375 L 8.220703125 5.162109375 
	L 5.109375 5.0830078125 L 5.109375 11.4375 L 5.109375 17.765625 L 9.328125 17.765625 L 13.546875 17.765625 L 13.546875 18.8203125 
	L 13.546875 19.875 L 8.2734375 19.875 L 3.0 19.875 L 3.0 11.4375 Z"
    set paddfile2 "M 17.0 13.0 L 17.0 15.0 L 15.0 15.0 L 15.0 16.0 L 17.0 16.0 L 17.0 18.0 L 18.0 18.0 L 18.0 16.0 L 20.0 16.0 L 20.0 15.0 L 18.0 15.0 L 18.0 13.0 L 17.0 13.0 Z"

    set pdelfile1 "M 3.0 11.4375 L 3.0 3.0 L 7.4296875 3.0 L 11.8330078125 3.0 L 14.28515625 5.4521484375 L 16.7109375 7.8779296875 L 16.7109375 9.6708984375 
	L 16.7109375 11.4375 L 15.65625 11.4375 L 14.6279296875 11.4375 L 14.548828125 9.9345703125 L 14.4697265625 8.4052734375 
	L 12.966796875 8.326171875 L 11.4638671875 8.2470703125 L 11.384765625 6.744140625 L 11.3056640625 5.2412109375 L 8.220703125 5.162109375 
	L 5.109375 5.0830078125 L 5.109375 11.4375 L 5.109375 17.765625 L 9.328125 17.765625 L 13.546875 17.765625 L 13.546875 18.8203125 
	L 13.546875 19.875 L 8.2734375 19.875 L 3.0 19.875 L 3.0 11.4375 Z"
    set pdelfile2 "M 12.0 13.0 L 12.0 13.0 L 19.5 13.0 L 19.5 15.25 L 12.0 15.25 Z"

    set prename1 "M 31.25 57.5 C 31.25 56.875 32.5 56.25 34.125 56.25 C 35.625 56.25 38.25 55.375 39.75 54.25 C 42.375 52.375 42.5 51.625 42.5 31.25 
	C 42.5 10.875 42.375 10.125 39.75 8.25 C 38.25 7.125 35.625 6.25 34.125 6.25 C 32.5 6.25 31.25 5.75 31.25 5.0 C 31.25 3.0 37.875 3.5 41.0 5.75 
	C 43.5 7.5 44.0 7.5 46.5 5.75 C 49.625 3.5 56.25 3.0 56.25 5.0 C 56.25 5.75 55.0 6.25 53.375 6.25 C 48.75 6.25 45.0 9.625 45.0 13.875 L 45.0 17.5 
	L 53.125 17.5 L 61.25 17.5 L 61.25 31.25 L 61.25 45.0 L 53.125 45.0 L 45.0 45.0 L 45.0 48.625 C 45.0 52.875 48.75 56.25 53.375 56.25 
	C 55.0 56.25 56.25 56.875 56.25 57.5 C 56.25 59.5 49.625 59.0 46.5 56.75 C 44.0 55.0 43.5 55.0 41.0 56.75 C 37.875 59.0 31.25 59.5 31.25 57.5 Z "
    set prename2 "M 58.75 31.25 L 58.75 20.0 L 51.875 20.0 L 45.0 20.0 L 45.0 31.25 L 45.0 42.5 L 51.875 42.5 L 58.75 42.5 L 58.75 31.25 Z "
    set prename3 "M 1.25 31.25 L 1.25 17.5 L 20.0 17.5 C 31.625 17.5 38.75 18.0 38.75 18.75 C 38.75 19.5 32.125 20.0 21.25 20.0 L 3.75 20.0 L 3.75 31.25 
	L 3.75 42.5 L 21.25 42.5 C 32.125 42.5 38.75 43.0 38.75 43.75 C 38.75 44.5 31.625 45.0 20.0 45.0 L 1.25 45.0 L 1.25 31.25 Z"


    set s {}
    set t {}
#puts "showContextMenu: w=$w fm=$fm x=$x y=$y rootx=$rootx rooty=$rooty mtype=$mtype"
#    set w "$fm.files.t"
    foreach i [$w selection] {
      #Это сторока из таблицы
      #Это путь к файлу или каталогу
      lappend s [lindex [$w item $i -value] 0]
      #Это тип субъекта
      lappend t [lindex [$w item $i -value] 1]
    }
    if {[winfo exists $fm.contextMenu]} {
	$::cmenudf destroy
    }
#В отдельном окне
    set m46 [winfo fpixels $fm 46m]
    set wcont [winfo width $w]
    set wrootx [winfo rootx $w]
#Если контекстное меню не умещается во фрейм, то оно создается в отдельном окне
#    if {$mtype == 1} {}
    if {[expr {($rootx + $m46) >  ($wrootx + $wcont)}]} {
	set mtype 1
#	catch {destroy $fm.contextMenu}
set fmWin ".cont"
	catch {destroy $fmWin}
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
	set cmenu1 [cmenu new $fmWin.contextMenu -tongue "0.5 0.5 0.5 0" -strokewidth 2 -pad 1m ]
    } else {
	set tp [winfo toplevel $w]
	if {$tp == "."} {
	    set tp ""
	}
	set cmenu1 [cmenu new $tp.contextMenu -tongue "0.5 0.5 0.5 0" -direction down -strokewidth 2 -pad 1m -height 6m]
    }
    eval "$cmenu1 config -command {catch {[set cmenu1] destroy};set ::fdmenu 1}"
    
    set canCtx [$cmenu1 canvas]
    set adddir [$canCtx create group]
    set adddir1 [$canCtx create path "$padddir1" -fill black -strokewidth 0 -parent $adddir]
    set adddir2 [$canCtx create path "$padddir2" -fill black -strokewidth 0 -parent $adddir]
set ::cmenudf $cmenu1
#Добавить команду separator а пока
    set cmd7 [$cmenu1 add separator]
    $cmd7 config -fillnormal gray70 -stroke {} -strokewidth 0  -height 0.5m -fillenter "##" -fillpress "##"
#    .contextMenu add separator
    if {$s != ""} {
      if {$t == "denied"} {
#        .contextMenu add command -label [mc "No access"] -command {}
#Добавить в add параметры для config
	set cmd1 [$cmenu1 add command -text [mc "No access"]]
	$cmd1 config -command {}
	
      }
      if {$t == "file" || [string range $t 0 1] == "f_"} {
	set renfile [$canCtx create group]
	set renfile1 [$canCtx create path "$prename1" -parent $renfile -stroke black]
	set renfile2 [$canCtx create path "$prename2" -parent $renfile -stroke black ]
	set renfile3 [$canCtx create path "$prename3" -parent $renfile -stroke black ]

	set addfile [$canCtx create group]
	set addfile1 [$canCtx create path "$paddfile1" -fill black -strokewidth 0 -parent $addfile]
	set addfile2 [$canCtx create path "$paddfile2" -fill black -strokewidth 0 -parent $addfile]

	set delfile [$canCtx create group]
	set delfile1 [$canCtx create path "$pdelfile1" -fill black -strokewidth 0 -parent $delfile]
	set delfile2 [$canCtx create path "$pdelfile2" -fill black -strokewidth 0 -parent $delfile]

        set cmd2 [$cmenu1 add command -height 7m -text "[mc {Delete file}]" -compound left]
	$cmd2 config -image "$canCtx $delfile"
	$canCtx delete $delfile
        eval "$cmd2 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::filedel $fm $s $typefb]; set ::fdmenu 1}"
	set cmd3 [$cmenu1 add command  -text "[mc {Rename file}]" -compound left]
	$cmd3 config -image "$canCtx $renfile"
	$canCtx delete $renfile
	set isvg [$cmd3 config -isvg]
	[$cmd3 canvas] itemconfigure $isvg -strokewidth 2.0

        eval "$cmd3 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::renameobj $fm.tekfolder $typefb  $s $fm]; set ::fdmenu 1}"

	set cmd9 [$cmenu1 add command  -text "Свойства файла" -compound left]
	$cmd9 config -image "fe_iconview"
        eval "$cmd9 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::propfile $s]; set ::fdmenu 1}"

	set cmd7 [$cmenu1 add command -text "[mc {Create an empty file}]" -compound left]
	$cmd7 config -image "$canCtx $addfile"
	$canCtx delete $addfile
	eval "$cmd7 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::createdir file  $fm.tekfolder $fm $typefb]; set ::fdmenu 1}"
	set cmd4 [$cmenu1 add separator]
      }
      if {$t == "directory" || $t == "d_directory"} {
	set deldir [$canCtx create group]
	set deldir1 [$canCtx create path "$pdeldir1" -parent $deldir]
	set deldir2 [$canCtx create path "$pdeldir2" -parent $deldir]

	set rendir [$canCtx create group]
	set rendir1 [$canCtx create path "$prename1" -parent $rendir -stroke black]
	set rendir2 [$canCtx create path "$prename2" -parent $rendir -stroke black ]
	set rendir3 [$canCtx create path "$prename3" -parent $rendir -stroke black ]
#        .contextMenu add command -label [mc "Delete directory"] -command [list [namespace current]::filedel $fm $s $typefb]
	set cmd4 [$cmenu1 add command -text "[mc {Delete directory}]" -compound left]
        eval "$cmd4 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::filedel $fm $s $typefb]; set ::fdmenu 1}"
	$cmd4 config -image "$canCtx $deldir"
	$canCtx delete $deldir
	set isvg [$cmd4 config -isvg]
	[$cmd4 canvas] itemconfigure $isvg -strokewidth 2.0

#        .contextMenu add separator
#        .contextMenu add command -label [mc "Rename directory"] -command [list [namespace current]::renameobj "$fm.tekfolder" $typefb  $s $fm]
	set cmd5 [$cmenu1 add command -text "[mc {Rename directory}]" -compound left]
	$cmd5 config -image "$canCtx $rendir"
	$canCtx delete $rendir
	eval "$cmd5 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::renameobj $fm.tekfolder $typefb  $s $fm]; set ::fdmenu 1}"

	set cmd9 [$cmenu1 add command -compound left -text "Свойства каталога" -image "fe_iconview"]
	$cmd9 config -compound left
	$cmd9 config -image "fe_iconview"
	eval "$cmd9 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::propfile $s ]; set ::fdmenu 1}"
      }
	set cmd6 [$cmenu1 add command -text "[mc {Create directory}]" -compound left]
	eval "$cmd6 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::createdir dir  $fm.tekfolder $fm $typefb]; set ::fdmenu 1}"
	$cmd6 config -image "$canCtx $adddir"
	$canCtx delete $adddir
    } else {
#    .contextMenu add command -label [mc "Create directory"] -command [list [namespace current]::createdir "dir"  $fm.tekfolder $fm $typefb]
    set cmd6 [$cmenu1 add command -text "[mc {Create directory}]" -compound left]
#puts "place cmd6=$cmd6 cmenu1=$cmenu1"
    $cmd6 config -image "$canCtx $adddir"
    $canCtx delete $adddir
    eval "$cmd6 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::createdir "dir"  $fm.tekfolder $fm $typefb]; set ::fdmenu 1}"

    if {$typefb != "dir"} {
#      .contextMenu add separator
#Добавить команду separator а пока
	set cmd7 [$cmenu1 add separator]
#      .contextMenu add command -label [mc "Create an empty file"] -command [list [namespace current]::createdir "file"  $fm.tekfolder $fm $typefb]
	set addfile [$canCtx create group]
	set addfile1 [$canCtx create path "$paddfile1" -fill black -strokewidth 0 -parent $addfile]
	set addfile2 [$canCtx create path "$paddfile2" -fill black -strokewidth 0 -parent $addfile]

	set cmd7 [$cmenu1 add command -text "[mc {Create an empty file}]" -compound left]
	eval "$cmd7 config -command {[set cmenu1] destroy;bind $fm <ButtonRelease-3> {};[list [namespace current]::createdir "file"  $fm.tekfolder $fm $typefb]; set ::fdmenu 1}"
	$cmd7 config -image "$canCtx $addfile"
	$canCtx delete $addfile
    }
    }
    set cmd7 [$cmenu1 add separator]

    if {$mtype == 0} {
	set cmd "bind $fm <ButtonRelease-3> {}; set ::fdmenu 1"
	set cmd1 [subst "bind $fm <ButtonRelease-3> {if {\"\%W\" != \"$w\"} {$cmd}}"]
	eval $cmd1
    }
    set parcm [winfo parent [$cmenu1 canvas]]
    if {[winfo class $parcm] != "femenu"} {
	tk busy hold $fm
    } else {
	    tk busy hold $fm
    }

    set topl [winfo toplevel $fm]
    if {$topl != $fm} {
	eval "bind [set fm]_Busy <ButtonRelease> {[set cmenu1] destroy;; set ::fdmenu 1}"
    } else {
	eval "bind [set fm]._Busy <ButtonRelease> {[set cmenu1] destroy;; set ::fdmenu 1}"
    }
if {0} {
    if {$mtype == 1} {
	eval "bind $topl <Configure> {[set cmenu1] destroy;; set ::fdmenu 1;bind $topl <Configure> {if {\"%W\" == $::FE::folder(w) && [winfo exist $::FE::folder(w).contextMenu]} {lower $::FE::folder(w)._Busy $::FE::folder(w).contextMenu}}}"
    }
}

    set cmd_fin [$cmenu1 add finish]
    $cmd_fin config -fillnormal "#f4f5f5" -stroke gray70
    eval "$cmd_fin config -command {catch {[set cmenu1] destroy};set ::fdmenu 1}"

#Ширина
    if {$mtype == 1} {
	set mbut [$cmenu1 place -x $rootx -y $rooty -in ".cont" ]
	place forget [$cmenu1 canvas]
	pack [$cmenu1 canvas] -side top -anchor nw
	wm state $fmWin normal
	wm geometry $fmWin +$rootx+$rooty
    } else {
	set mbut [$cmenu1 place -x $x -y $y -in $fm]
    }
    if {$mtype == 1} {
	set cmd "bind $topl <Configure> {if {\[winfo exist {.cont.contextMenu}\]} {bind .cont.contextMenu <ButtonRelease-3> {}};bind $topl <Configure> {};bind $topl <FocusOut> {}; catch {[set cmenu1] destroy}; set ::fdmenu 1}"
	eval $cmd
	set cmd "bind $topl <FocusOut> {if {\[winfo exist {.cont.contextMenu}\]} {bind .cont.contextMenu <ButtonRelease-3> {}};bind $topl <FocusOut> {};bind $topl <Configure> {}; catch {[set cmenu1] destroy}; set ::fdmenu 1}"
	eval $cmd
    }
    set ::fdmenu 0
    vwait ::fdmenu
    if {[tk busy status "."]} {
	tk busy forget "."
    }
    if {[tk busy status $fm]} {
	tk busy forget $fm
    }

}
  proc moveConfigMenu {} {
	set ind1 [string first "+" $::geoFE]
	set ind2 [string last "+" $::geoFE]
	set x0 [string range $::geoFE $ind1+1 $ind2-1]
	set y0 [string range $::geoFE $ind2+1 end]
	set ::geoFE [wm geometry .fe]
	set ind1 [string first "+" $::geoFE]
	set ind2 [string last "+" $::geoFE]
	set x1 [string range $::geoFE $ind1+1 $ind2-1]
	set y1 [string range $::geoFE $ind2+1 end]
	set ::geoConf [wm geometry .butconfig]
	set ind1 [string first "+" $::geoConf]
	set ind2 [string last "+" $::geoConf]

	set xb [string range $::geoConf $ind1+1 $ind2-1]
	set yb [string range $::geoConf $ind2+1 end]
#puts "moveCofigMenu: xb=\"$xb\" x1=\"$x1\" x0=\"$x0\" yb=\"$yb\" y1=\"$y1\" y0=\"$y0\" "
	wm geometry .butconfig "+[expr {$xb + ($x1 - $x0)}]+[expr {$yb + ($y1 - $y0)}]"
  }
proc showSubMenu {w fm obj {mtype 0}} {
#	set ::submenu [cmenu new $fm.subMenu -tongue "0.45 0.5 0.55 2m" -strokewidth 2 -pad 1m]
#####################
set direct left
#    if {$::submenu != ""}  {
#	$::submenu destroy
#    }
    if {[info exist ::submenu]} {
	if {[info exist $::submenu]} {
	    $::submenu destroy
	}
    }


    if {$mtype == 1} {
	set fmWin ".$fm"
	catch {destroy $fmWin}
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
#	set ::submenu [cmenu new $fmWin.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
	destroy $fmWin.$fm
	set ::submenu [cmenu new $fmWin.$fm -tongue "0.30 0.20 0.45 2m" -direction $direct -strokewidth 2 -pad 1m  -fillnormal snow -stroke gray70 -direction $direct]
    } else {
#	set ::cmenubut [cmenu new $win.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
	set tl [winfo toplevel $w]
	if {$tl == "."} {
	    set tl ""
	}
#	destroy .subMenu
	set ::submenu [cmenu new $tl.subMenu -tongue "0.30 0.20 0.45 2m" -strokewidth 2 -pad 1m -fillnormal snow -stroke gray70 -direction $direct]
    }
	set i 0
#	foreach hcol  [list Размер Дата Полномочия] {}
	foreach hcol  "$::FE::folder(displaycolumns)" {
	    set ch$i [$::submenu add check -text "$hcol" -variable ::FE::displaycolumns($hcol)]
	    set chsep [$::submenu add separator ]
		$chsep config -stroke "" -fillnormal "" -fillenter "##"
#Состав расширенного просмотра
#	    set ::FE::displaycolumns($hcol) 1
	    incr i
	}
#	    set ch$i [$::submenu add check -text [::msgcat::mc "$hcol"] -variable ::FE::displaycolumns($hcol)]
#puts "showSubMenu END: i=$i hcol=$hcol"
    set chsep [$::submenu add separator ]
    $chsep config -stroke "" -fillnormal "" -fillenter "##"
    set chsep [$::submenu add finish]

#    ::FE::detailedview $::FE::folder(w)

    return $::submenu
}

proc showConfigMenu { oow fm direct {mtype 0}} {
# oow - кнопка, для которой создаем меню
# fm - имя виджета меню без точки
#direct - направление язычка
# mtype - 0 меню создается в окне кнопки; 1 - меню создается в отдельном окне 
#set mtype 0

###################################
#puts "createConfigMenu 1 oow=$oow fm=$fm"
    set mm2px [winfo pixels [$oow canvas] 1m]
#Создаётся отдельное окно для меню
    if {[info exist ::cmenubut]} {
	if {[info exist $::cmenubut]} {
	    $::cmenubut destroy
	}
    }
    if {$mtype == 1} {
	set fmWin ".$fm"
	catch {destroy $fmWin}
	toplevel $fmWin -class femenu
	wm overrideredirect $fmWin 1
	wm state $fmWin withdraw
	set ::cmenubut [cmenu new $fmWin.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
    } else {
	set win [winfo toplevel [$oow canvas]]
	if {$win == "."} {
	    set win ""
	}
	destroy $win.$fm
	set ::cmenubut [cmenu new $win.$fm -tongue "0.45 0.5 0.55 2m" -direction $direct -strokewidth 2 -pad 1m -command "" -fillnormal snow  -stroke gray70 -height 6m]
    }
#puts "showConfigMenu 1_2"
    set ch1 [$::cmenubut add check -text {Папки вверху} -variable  ::FE::folder(foldersfirst)]
#    set ::FE::folder(foldersfirst) 0
    $ch1 config -command "[namespace current]::columnSort \$::FE::folder(w).files.t \$::FE::folder(column) \$::FE::folder(direction)"

#    eval "variable foldersfirst;$ch1 config -command {puts \\\"Папки вверну foldersfirst=\$foldersfirst \\\"}"
#puts "createConfigMenu 1_3"
#    $ch1 config -text "Папки вверху"
    set ch1 [$::cmenubut add separator]
    set gr [[$::cmenubut canvas] create group]
    set iprev [[$::cmenubut canvas] create path "M 3 3 L 13 13 3 23" -strokewidth 2 -parent $gr]

# -displaymenu enter
#enter - отображать меню при наведении на кнопку с меню
#release - отображать меню при щелчке по кнопке с меню
    set chcas [$::cmenubut add cascade -text "Состав данных" -menu "" -fillopacity 0.2 -fillenter "#3584e4" -strokewidth 0 -compound none -ipad "4.5c 3m 2.5m 4m"  -displaymenu release]
#puts "createConfigMenu 1_3 Состав_данных=$chcas menu=$fm.subMenu"

#puts "СОСТАВ ДАННЫХ=$chcas ::cmenubut=$::cmenubut chcas=$chcas iprev=$iprev"
    set ch1 [$::cmenubut add separator]
#Создаем SubMenu
#set sm [showSubMenu [$chcas canvas] "submenu" "new" 1]
#puts "createConfigMenu 1_4"
#set sm [showSubMenu [$chcas canvas] "submenu" "new" 0]
set sm [showSubMenu [$chcas canvas] "submenu" "new" $mtype]
    $chcas config -menu $sm -displaymenu release
#puts "createConfigMenu 1_5 obj_Menu=$oow  Menu==$::cmenubut  obj_subMenu=$chcas subMenu=$$sm"

#puts "createConfigMenu 1_4 sm=$sm chcas=$chcas"
    $chcas config -command ""
    set cmd ""
	foreach hcol  "$::FE::folder(displaycolumns)" {
	    append cmd "set ::FE::displaycolumns($hcol) \$::FE::displaycolumns($hcol);"
	}
    $chcas config -command "$cmd;::FE::detailedview \$::FE::folder(w)"


    set cr0 [$::cmenubut add radio " -variable ::FE::folder(details) -text {Только имена} -value 0"]
    eval "$cr0 config -command {\$::FE::folder(w).files.t configure -displaycolumns \{\}; \$::FE::folder(w).files.t column \{#0\} -stretch 1}"
#    eval "$cr0 config -command {puts \\\"Укороченный список\\\"}"
    set ch1 [$::cmenubut add separator -fillnormal ""]

    set cr1 [$::cmenubut add radio "-variable ::FE::folder(details) -text {Расширенный список} -value 1"]
    eval "$cr1 config -command {[namespace current]::detailedview \$::FE::folder(w)}"
#    eval "$cr1 config -command {puts {Расширенный список}}"
    set ch1 [$::cmenubut add separator]
#    $ch1 config -text ""
    set chlast [$::cmenubut add check "-text {Папки и файлы раздельно} -variable ::FE::folder(sepfolders)"]
    $chlast config -command "[namespace current]::gosepfolders .fe $::FE::folder(typew) $::FE::folder(typefb)"
#    $chlast config -command "puts {Папки и файлы раздельно}"

    set ch1 [$::cmenubut add separator]
    set mbut [$::cmenubut add finish]
#Иконки на кнопках в меню можно выставлять после команды add finish !!!!!
    $chcas config -image "[$::cmenubut canvas] $gr" 
    [$::cmenubut canvas] delete $gr

    $mbut config -command ""
    $oow config -menu $::cmenubut
#    return $mbut
#puts "creatConfigMenu end: cmenu=$::cmenubut callout=$mbut"
$::FE::folder(configureBtn) config -command ""
$::FE::folder(configureBtn) config -menu $::cmenubut

return $::cmenubut
}

## Code to do the sorting of the tree contents when clicked on
  proc columnSort {tree col direction } {
    set ::FE::folder(column) $col
    set ::FE::folder(direction) $direction
    set ncol [list fullpath size]
    # Build something we can sort
    set data {}
    set listfile [list]
    set listdir [list]
    if {$::FE::folder(typew) != "frame" } {
	set w1 [winfo toplevel $tree]
    } else {
	set w1 $::FE::folder(w)
    }
#puts "columnSort START: tree=$tree col=$col direction=$direction w1=$w1"
    foreach row [$tree children {}] {
      if {"$w1.dirs.t" == $tree} {
	    set type "directory"
      } else { 
	    set type [$tree set $row "type"]
      }
#puts "columnSort type=$type fullpath=[$tree set $row {fullpath}]"
      if {$col == "#0"} {
        lappend data [list [$tree set $row "fullpath"] $row]
        if {[string range $type 0 1] == "f_"  || [string range $type 0 1] != "d_"} {
    	    lappend listfile [list [$tree set $row "fullpath"] $row]
        } else {
    	    lappend listdir [list [$tree set $row "fullpath"] $row]
        }
      } else {
        lappend data [list [$tree set $row $col] $row]
	if {$col == "date"} {
    	    if {[string range $type 0 1] == "f_"} {
    		lappend listfile [list [$tree set $row "dateorig"] $row]
    	    } else {
    		lappend listdir [list [$tree set $row "dateorig"] $row]
    	    }
	} else {
    	    if {[string range $type 0 1] == "f_"} {
    		lappend listfile [list [$tree set $row $col] $row]
    	    } else {
    		lappend listdir [list [$tree set $row $col] $row]
    	    }
        }
      }
    }

    set dir [expr {$direction ? "-decreasing" : "-increasing"}]
    #Оставляем .. в начале списка
    set r 0
    set data1 [lrange $data 0 end]
    set listdir1 [lrange $listdir 0 end]

    # Now reshuffle the rows into the sorted order
    if {$::FE::folder(foldersfirst)} {
#puts "listdir1=$listdir1"
	foreach info [lsort -dictionary -index 0 "$dir" "$listdir1"] {
    	    $tree move [lindex $info 1] {} [incr r]
	}
#puts "listfile=$listfile"
	foreach info [lsort -dictionary -index 0 "$dir" "$listfile"] {
    	    $tree move [lindex $info 1] {} [incr r]
	}
    } else {
#puts "NotFirst listfile=$listfile"
	foreach info [lsort -dictionary -index 0 "$dir" "$listfile"] {
    	    $tree move [lindex $info 1] {} [incr r]
	}
#puts "NotFirst listdir1=$listdir1"
	foreach info [lsort -dictionary -index 0 "$dir" "$listdir1"] {
    	    $tree move [lindex $info 1] {} [incr r]
	}
    
    }

    # Switch the heading so that it will sort in the opposite direction
    $tree heading $col -command [list [namespace current]::columnSort $tree $col [expr {!$direction}]] \
    state [expr {$direction?"!selected alternate":"selected !alternate"}]

    if {[ttk::style theme use] eq "aqua"} {
      # Aqua theme displays native sort arrows when user1 state is set
      $tree heading $col state "user1"
    } else {
      $tree heading $col -image [expr {$direction?"fe_upArrow":"fe_downArrow"}]
    }
#puts "columnSort END: tree=$tree col=$col direction=$direction"
  }

  proc   helptools {fromw tow xtow text anchor} {
    catch {destroy $fromw}
    if {$text == ""} {
	return
    }
#Имя кнопки
    set btn [string range $tow [string last "." $tow]+1 end]
    if {$btn == "hiddencb" && $::FE::folder(hiddencb)} {
	set text "Go no$btn"
    }
    label $fromw -text "Help" -anchor nw -justify left -bg #ffe0a6
    set tr [mc $text]
    $fromw configure -text $tr
    raise $tow
    place $fromw  -in $tow -relx $xtow -rely 1.0 -anchor $anchor
    raise $fromw
  }

  proc initfe {typefb otv args} {
# 1: the configuration specs
#
    catch {unset ::FE::data}
    set ::FE::folder(otv) $otv

    set few [winfo pixels . 10c]
    set feh [winfo pixels . 15c]
    if {[info exist ::FE::folder]} {
	set foldersfirst $::FE::folder(foldersfirst)
	set sepfolders $::FE::folder(sepfolders)
	set details $::FE::folder(details)
	
    }
    set specs {
	{-typew "" "" "window"}
	{-widget "" "" ""}
	{-defaultextension "" "" ""}
	{-filetypes "" "" ""}
	{-initialdir "" "" ""}
	{-initialfile "" "" ""}
	{-parent "" "" "."}
	{-title "" "" ""}
	{-sepfolders "" "" -1}
	{-foldersfirst "" "" -1}
	{-sort "" "" "#0"}
	{-reverse "" "" 0}
	{-details "" "" -1}
	{-hidden "" "" -1}
	{-width "" "" -10}
	{-height "" "" -10}
	{-x "" "" 5}
	{-y "" "" 5}
	{-relwidth "" "" 1.0}
	{-relheight "" "" 1.0}
	{-size "" "" 1}
	{-date "" "" 0}
	{-permissions "" "" 0}
    }
    set specs_ORIG {
	{-typew "" "" "window"}
	{-widget "" "" ""}
	{-defaultextension "" "" ""}
	{-filetypes "" "" ""}
	{-initialdir "" "" ""}
	{-initialfile "" "" ""}
	{-parent "" "" "."}
	{-title "" "" ""}
	{-sepfolders "" "" -1}
	{-foldersfirst "" "" -1}
	{-sort "" "" "#0"}
	{-reverse "" "" 0}
	{-details "" "" -1}
	{-hidden "" "" -1}
	{-width "" "" -10}
	{-height "" "" -10}
	{-x "" "" 5}
	{-y "" "" 5}
	{-relwidth "" "" 1.0}
	{-relheight "" "" 1.0}
    }
#place $w -in [winfo parent $w] -x 5 -y 5 -relwidth 1.0 -relheight 1.0 -width -10 -height -80

#puts "initfe: specs=$specs"
    tclParseConfigSpec ::FE::data $specs "" [lindex $args 0]
#    tclParseConfigSpec ::FE::data [subst "$specs"] "" [lindex $args 0]
#parray ::FE::data
    if { $::FE::data(-typew) == "window" } {
	if {$::FE::data(-width) == -10} {
	    set ::FE::data(-width) $few
	}
	if {$::FE::data(-height) == -10} {
	    set ::FE::data(-height) $feh
	}
    }
    if {[info exist foldersfirst]} {
#puts "initfe: foldersfirst=$foldersfirst"
	set ::FE::folder(foldersfirst) $foldersfirst
	set ::FE::data(foldersfirst) $foldersfirst
	set ::FE::folder(sepfolders) $sepfolders
	set ::FE::data(sepfolders) $sepfolders
	set ::FE::data(details) $details
    }
    if {[trace info variable ::FE::displaycolumns] != ""} {
	if {$::tcl_version >= 9} {
	    trace remove variable ::FE::displaycolumns write ::FE::trace_columns
	} else {
	    trace vdelete ::FE::displaycolumns w ::FE::trace_columns
	}
    }
  set ::FE::displaycolumns(size) $::FE::data(-size)
  set ::FE::displaycolumns(date) $::FE::data(-date)
  set ::FE::displaycolumns(permissions) $::FE::data(-permissions)


    if {$::FE::data(-widget) == ""} {
	set rand [expr int(rand() * 10000)]
	set ::FE::data(-widget) ".fe$rand"
    }
    set w $::FE::data(-widget)
    catch {destroy $w}
    set typew $::FE::data(-typew)
    set initdir $::FE::data(-initialdir)
    if {$initdir == ""} {
	set initdir [pwd]
    }
    
    if {![file readable "$initdir"]} {
        tk_messageBox -title "Просмотр папки" -icon info -message "Каталог не доступен (initfe):\n$initdir\nПереходим в домашний каталог" -parent .
	set initdir $::env(HOME)
        if {[tk windowingsystem] == "win32"} {
#    	    set initdir [encoding convertfrom cp1251 $initdir ]
    	    set initdir [string map {"\\" "/"} $initdir]
        }
    }
    if {$::FE::data(-filetypes) == ""} {
	set msk {{"All files" "*"}}
    } else {
	set msk $::FE::data(-filetypes)
    }
    set ::FE::folder(typew) $typew
    set ::FE::folder(typefb) $typefb
    set ::FE::folder(w) $w
    trace add variable ::FE::displaycolumns write ::FE::trace_columns

    set ::FE::folder(initialfile) ""
    if {$typefb == "dir"} {
	set ::FE::folder(sepfolders) 0
    } else {
	if {$::FE::data(-sepfolders) == -1} { 
	    if { ![info exists ::FE::folder(sepfolders)]} {
		set ::FE::folder(sepfolders) 0
	    }
	} else {
		set ::FE::folder(sepfolders) $::FE::data(-sepfolders)
	}
	if {$::FE::data(-foldersfirst) == -1} { 
	    if { ![info exists ::FE::folder(foldersfirst)]} {
		set ::FE::folder(foldersfirst) 1
	    }
	} else {
		set ::FE::folder(foldersfirst) $::FE::data(-foldersfirst)
	}
	if {$::FE::data(-details) == -1} {
	    if {![info exists ::FE::folder(details)]} {
		set ::FE::folder(details) 0
	    }
	} else {
		set ::FE::folder(details) $::FE::data(-details)
	}
    }
#    set ::FE::folder(foldersfirst) $::FE::data(-foldersfirst)
    set ::FE::folder(hiddencb) $::FE::data(-hidden)
#parray ::FE::folder
    if {$::FE::folder(history) == ""} {
	lappend ::FE::folder(history) $initdir
	set ::FE::folder(histpos) 0
    }
    set wres [wm resizable .]
    if {$typew == "frame"} {
	frame $w -bg #d9D9D9
set zz [winfo toplevel $w]
#	destroy $w
	all_busy_hold $zz
#	frame $w -bg #d9D9D9
	raise $w 
	if {$zz == "."} {
	    eval "bind $zz <Configure> {catch {lower ._Busy $::FE::folder(w)}}"
#	    eval "bind $zz <Configure> {catch {lower [set w]_Busy $::FE::folder(w)}}"
	    bind $::FE::folder(w) <Enter> {if {[winfo exist ._Busy]} {event generate ._Busy <ButtonRelease>}}
	} else {
	    eval "bind $zz <Configure> {lower [set zz]._Busy $::FE::folder(w)}"
	    bind $::FE::folder(w) <Enter> {if {[winfo exist [set zz]._Busy]} {event generate [set zz]._Busy <ButtonRelease>}}
	}
    } else {
      if {$::FE::folder(sepfolders)} {
        set tw [expr {$::scrwidth + 100}] 
      } else {
        set tw $::scrwidth
      }
      set tw $::scrwidth

      set th [expr $::scrheight - 100]
      set geometr $tw
      append geometr "x"
      append geometr $th
  #Считываем размеры экрана в пикселях
      set rw [winfo screenwidth .]
      set rh [winfo screenheight .]
      if { $rw <= $rh } {
         append geometr "+0+0"
      } else {
#Координаты главного окна
	set rgeom [wm geometry .]
	set rgf [string first "x" $rgeom]
	set rw [string range $rgeom 0 $rgf-1]
	set rg [string first "+" $rgeom]
	set xx [string range $rgeom $rgf+1 $rg-1]
	set rg1 [string range $rgeom $rg+1 end]
	if {$rw <= $tw} {
#Окно fe уже главного окна
    	    append geometr +$rg1
        } else {
	    set off [expr ($rw - $tw) / 2]
	    set rg2 [string first "+" $rg1]
	    incr rg
	    incr rg2 -1
	    set offw [string range $rg1 0 $rg2]
	    set offw1 [expr $offw + $off]
	    incr rg2 2
	    set offw2 [string range $rg1 $rg2  end]
	    set offw2 [expr $offw2 + ($xx - $th)/2]
    	    append geometr "+$offw1+$offw2"

        }
      }
      toplevel $w -bd 2  -relief groove -bg #d9d9d9
      wm geometry $w $geometr
      bind $w <Destroy> {if {"%W" == $::FE::folder(w)} {::FE::fecancel $::FE::folder(typew) $::FE::folder(w) $::FE::folder(typefb) $::FE::folder(otv)}}
      bind $w <Configure> {if {"%W" == $::FE::folder(w) && [winfo exist $::FE::folder(w).contextMenu]} {lower $::FE::folder(w)._Busy $::FE::folder(w).contextMenu}}
      if {$::FE::data(-width) > 0 && $::FE::data(-height) > 0} {
    	    set geom $::FE::data(-width)
    	    append geom "x"
    	    append geom $::FE::data(-height)
    	    wm geometry $w $geom
      } elseif {[info exists ::Fegeo]} {
	    wm geometry $w $::Fegeo
      }
 #Конфигурирование виджета под смартфон
  #Ширина 75 mm
  #Высота 160 mm
  wm minsize $w [expr {int([winfo fpixels $w 75m])}] [expr {int([winfo fpixels $w 80m])}]
#  wm minsize . [expr $::scrwidth * 2] $::scrheight
#Устанавливаем последнюю геометрию окна

#Окно не может перекрываться (yes)
#      wm attributes $w -topmost yes   ;# stays on top - needed for Linux
      if {$typefb == "dir"} {
        if {$::FE::data(-title) != ""} {
    	    wm title $w [mc "$::FE::data(-title)"]
        } else {
    	    wm title $w [mc "Choose directory"]
        }
        wm iconphoto $w fe_icondir
      } else {
        if {$::FE::data(-title) != ""} {
    	    wm title $w [mc "$::FE::data(-title)"]
        } else {
    	    wm title $w [mc "Choose file"]
	}
        wm iconphoto $w fe_iconfile
      }
    }
    set fm "$w"
    set f3 [panedwindow $w.f3 -orient horizontal -sashwidth 2m]
#  -background red

	array set fontinfo [font actual [[label $f3.dummy] cget -font]]
	set font [list $fontinfo(-family) -14]
	destroy $f3.dummy
	$f3 add [ttk::frame $fm.dirs]
#	$f3 add [frame $fm.dirs]
    set data(dirArea) [ttk::treeview $fm.dirs.t -columns {fullpath} -displaycolumns {} -xscrollcommand [list [namespace current]::hidescroll $fm.dirs.x]]
    eval "$fm.dirs.t heading {#0} -text {[mc {Folders}]} -image fe_downArrow -command {[namespace current]::columnSort $fm.dirs.t {#0} 1} "
    if {$::typetlf} {
	$fm.dirs.t column "#0" -stretch 1 -width 200 -anchor w
    } else {
	$fm.dirs.t column "#0" -stretch 1 -width 150 -anchor w
    }
	ttk::scrollbar $fm.dirs.y -command [list $fm.dirs.t yview]
	ttk::scrollbar $fm.dirs.x -orient horizontal -command [list $fm.dirs.t xview]
    $fm.dirs.t configure -xscroll [list [namespace current]::hidescroll $fm.dirs.x ]
    $fm.dirs.t configure -yscroll [list [namespace current]::hidescroll $fm.dirs.y ]

	grid $fm.dirs.t $fm.dirs.y -sticky ns
	grid $fm.dirs.x -sticky we
	grid $fm.dirs.t -sticky news -padx {2 0} -pady {0 0}
	grid columnconfigure $fm.dirs 0 -weight 1
	grid rowconfigure $fm.dirs 0 -weight 1
    eval "bind $fm.dirs.t <Double-1> {[namespace current]::selectdir $fm.dirs.t $typew $typefb 2 $otv}"
    eval "bind $fm.dirs.t <ButtonRelease-1> {[namespace current]::selectdir $fm.dirs.t $typew $typefb 1 $otv}"
    eval "bind $fm.dirs.t <ButtonPress-3> {[namespace current]::showContextMenu %W %x %y %X %Y $w $typefb}"

	$f3 add [ttk::frame $fm.files]
#	$f3 add [frame $fm.files]
    set ::FE::folder(panedwindow) $f3
    set ::FE::folder(panedir) $fm.dirs
    set ::FE::folder(panefile) $fm.files
#    eval "$::FE::folder(panedwindow) forget 0"
    $f3 forget $fm.dirs

    ttk::scrollbar $fm.files.y -orient vertical -command "$fm.files.t yview"
    ttk::scrollbar $fm.files.x -orient horizontal -command "$fm.files.t xview"
if {0} {
    if {$typefb != "dir"} {
      ttk::treeview $fm.files.t -columns {fullpath type size date dateorig permissions} -displaycolumns {size date permissions} 
    } else {
      ttk::treeview $fm.files.t -columns {fullpath type size permissions} -displaycolumns {permissions} 
    }
}
      ttk::treeview $fm.files.t -columns {fullpath type size date dateorig permissions} -displaycolumns {size date permissions} 


    $fm.files.t configure -xscroll [list [namespace current]::hidescroll $fm.files.x ]
    $fm.files.t configure -yscroll [list [namespace current]::hidescroll $fm.files.y ]
    
    set ::FE::folder(displaycolumns) [$fm.files.t cget -displaycolumns]
    set ::FE::folder(width0) [$fm.files.t column "#0" -width]

    eval "$fm.files.t heading {#0} -text {[mc {Folders and files}]} -image fe_upArrow -command {[namespace current]::columnSort $fm.files.t {#0} 0} "
    if {$typefb == "dir"} {
	$fm.files.t heading "#0" -text  [mc {Folders}]
    }

    if {$typefb != "dir" || $::FE::folder(sepfolders) == 0} {
      eval "$fm.files.t heading size -text {[mc {Size}]} -image fe_upArrow -command {[namespace current]::columnSort $fm.files.t size 0}"
      eval "$fm.files.t heading date -text {[mc {Date}]} -image fe_upArrow -command {[namespace current]::columnSort $fm.files.t date 0}"
      eval "$fm.files.t heading permissions -text {[mc {Permissions}]} -image fe_upArrow -command {[namespace current]::columnSort $fm.files.t permissions 0}"
      $fm.files.t column date -stretch 0 -width 80 -anchor e
      $fm.files.t column size -stretch 0 -width 80 -anchor e
      $fm.files.t column "#0" -stretch 0 -width 170 -anchor w
    } else {
      $fm.files.t column size -stretch 1 -width 0 -anchor e
      $fm.files.t column "#0" -stretch 1 -width 75 -anchor w
    }

    eval "bind $fm.files.t <Double-1> {[namespace current]::selectobj $fm.files.t $typew $typefb 2 $otv}"
    eval "bind $fm.files.t <ButtonRelease-1> {[namespace current]::selectobj $fm.files.t $typew $typefb 1 $otv}"
    eval "bind $fm.files.t <ButtonPress-3> {[namespace current]::showContextMenu %W %x %y %X %Y $w $typefb 0}"

    frame $fm.buts  -bg #d9d9d9
#    eval "ttk::button $fm.buts.ok -text [mc {Done}]  -command {[namespace current]::fereturn $typew $fm $typefb $otv}"
    set cbut [eval "cbutton new $fm.buts.ok -type round  -text [mc Done]   -command {[namespace current]::fereturn $typew $fm $typefb $otv}"]
    set ::FE::folder(firstOO) $cbut

#    eval "ttk::button $fm.buts.cancel -text [mc {Cancel}]  -command {[namespace current]::fecancel $typew $fm $typefb $otv}"
    set cbut [eval "cbutton new $fm.buts.cancel -type round  -text [mc Cancel]   -command {[namespace current]::fecancel $typew $fm $typefb $otv}"]
    pack $fm.buts.ok $fm.buts.cancel -side right -padx 1m
#    $fm.buts.cancelack  -side right  -padx 1m

    pack $fm.buts -side bottom -fill x -padx 1m -pady 1m
    pack [ttk::separator $fm.sepbut] -side bottom -fill x -expand 0 -pady 0

    frame $fm.titul  -relief flat -bg white
    if {$::FE::data(-title) != ""} {
    	set ltit [mc "$::FE::data(-title)"]
    } else {
	if {$typefb == "dir"} {
    	    set ltit [mc "Choose folder"]
	} else {
    	    set ltit [mc "Choose file"]
	}
    }
    if {$typew == "frame"} {
	label $fm.titul.labzag -text $ltit -relief flat -bg skyblue -justify center
	pack $fm.titul.labzag -side top -fill x -expand 1
    }
#   label $fm.titul.lab  -relief flat -bg skyblue -justify center
    

	# f1: the toolbar
	#
    set win $w
    set dataName [winfo name $win]

	set f1 [ttk::frame $fm.titul.tools -class Toolbar]
	set data(bgLabel) [ttk::label $f1.bg -style Toolbutton]
#	set listBtn [list "upBtn fe_up goup" "prevBtn fe_prev goprev" "nextBtn fe_next gonext"]
#	set listBtn [list up prev next home hiddencb ]

    if {$typefb != "dir"} {
	set listBtn [list up prev next home "configure" hiddencb adddir addfile "update"]
    } else {
	set listBtn [list up prev next home "configure" hiddencb "configure" adddir "update"]
    }

	foreach {op} $listBtn {
	    set Btn "[set op]Btn"
	    set feimage "fe_[set op]"
	    set feproc "go[set op]"
#puts "Btn=$Btn feimage=$feimage feproc=$feproc"
	    set data($Btn) [ibutton new $f1.$op -height 7m -width 7m -pad 0m] 
	    set ::FE::folder($Btn) $data([set Btn])
	    $data([set Btn]) config -text {} -help "[mc {Go up}]" -strokewidth 0.5 -fillnormal #eff0f1 -stroke skyblue 
	    eval "$data($Btn) config -image $feimage"
	    set tfb ""
	    set totv ""
	    if {$op == "hiddencb"} {
		set ::FE::folder(hiddencb) 0
		set tfb $typefb
		set totv $otv
#    eval "bind $f1.hiddencb <Enter> {[namespace current]::gohelphiddencb  $fm $f1 } "
#    eval "bind $f1.hiddencb <Leave> {place forget $fm.helpview}"
	    }
	    eval "$data($Btn) config -command {[namespace current]::$feproc $fm $typefb $tfb $totv}"
	    
	    set strhelp [mc "Go [set op]"]
	    set strhelp [list "$strhelp"]
#Для развязки во времени двух bind (ibutton и canvas) прменяем after <задержка> [list ...]
	    [namespace current]::helptools $fm.helpview $f1.$op 0.0  $strhelp nw
	    eval "bind $f1.$op <Enter> {after 10 [list [namespace current]::helptools $fm.helpview $f1.$op 0.0  $strhelp nw]}"
	    eval "bind $f1.$op <Leave> {catch {place forget $fm.helpview}}"

#	    eval "bind $data($Btn) <Enter> {[namespace current]::helptools $fm.helpview $data($Btn) 0.0  {[mc {Go up}]} nw}"
#	    eval "bind $data($Btn) <Leave> {place forget $fm.helpview}"
	    pack [$data($Btn) canvas] -side left -fill both -expand 0 -padx 0
	}
##############Кнопка Меню настройки просмотра #################
#	$data(configureBtn) config -command "place forget $fm.helpview;update;after 20;puts STARTshowconfigmenu;puts [set data(configureBtn)];[namespace current]::showConfigMenu [$data(configureBtn) canvas] [set fm]"
#	$data(configureBtn) config -command "place forget $fm.helpview;update;after 20;[namespace current]::showConfigMenu [$data(configureBtn) canvas] [set fm]"
[namespace current]::showConfigMenu $data(configureBtn) ffmm up 0
#	$data(configureBtn) config -command "place forget $fm.helpview;update;after 20;[namespace current]::showConfigMenu $data(configureBtn) ffmm up 0"
	$data(configureBtn) config -command ""
#$data(configureBtn) config -command "set ::FE::folder(details) \$::FE::folder(details) "
$data(configureBtn) config -command "set ::FE::folder(foldersfirst) \$::FE::folder(foldersfirst);set ::FE::folder(details) \$::FE::folder(details); set ::FE::folder(sepfolders) \$::FE::folder(sepfolders)" 
$data(configureBtn) config  -displaymenu release

	$data(prevBtn) config -state disabled
	$data(nextBtn) config -state disabled
	if {![info exists ::env(HOME)]} {
		$data(homeBtn) state disabled
	}

	place $data(bgLabel) -relheight 1 -relwidth 1

set labLang [ibutton new  $f1.lang -text "" -command {} -strokewidth 0 -fillenter "##" -fillpress "##" -fillnormal "" -width 6m  -height 4m -pad "0 1m 0 0"]
set gradru [$f1.lang gradient create linear -stops \
  {{0.0 white} {0.333 white} {0.333 blue} {0.666 blue} {0.666 red} {1.0 red}} \
  -lineartransition {0 0 0 1}]
set objru [$f1.lang create path "M 0 0  L 50 0  L 50 30 L 0 30 Z" -fill $gradru -stroke "" ]
$labLang config -image "$f1.lang $objru"
$f1.lang delete $objru
	pack [$labLang canvas] -side right -anchor e -pady 0 -fill x -expand 0

    pack $fm.titul.tools -side left -anchor nw -fill x -expand 1

    labelframe $fm.filter  -bd 0 -labelanchor w

#Текущий каталог 
    set ftd [ttk::frame $fm.tekfolder]
    label $fm.tekfolder.lab -text "[mc {Current directory}]:" -bd 0 -anchor nw -font TkTextFont -background "#bbf9fe"
#  -font fontfe
    set dirlist [lindex $::FE::folder(history) 0]
    foreach d $::FE::folder(history) {
        if {[lsearch -exact $dirlist $d] == -1} {
    	    lappend dirlist $d
        }
    }
    if {![info exists initdir]} {
	if {[info exists ::env(HOME)] && ![string equal $::env(HOME) /]} {
	    lappend dirlist $::env(HOME)
	}
    } else {
	lappend dirlist $initdir
    }

    ttk::combobox $fm.tekfolder.ldir -width 0 -values $dirlist -textvariable ::FE::folder(tek)
    eval "bind $fm.tekfolder.ldir <<ComboboxSelected>> {[namespace current]::selectobj $fm.files.t $typew $typefb 3 $otv}"
    eval "bind $fm.tekfolder.ldir <Key-Return> {[namespace current]::selectobj $fm.files.t $typew $typefb 3 $otv}"
   $fm.tekfolder.ldir delete 0 end
   $fm.tekfolder.ldir insert end [lindex $dirlist end]
    pack $fm.tekfolder.lab -side left -fill none -pady {0.5m 0}
    pack $fm.tekfolder.ldir -side left -fill x -expand 1 -pady {0.5m 0}
    
#Установка фильтра
    if {$typefb != "dir"} {
	set msk1 [list]
	foreach line $msk {
	    foreach {a b} $line {
		set lb ""
		foreach bb $b {
		    if {[string range $bb 0 0] == "\."} {
			append lb "*$bb "
		    } else {
			append lb "$bb "
		    }
		}
		lappend msk1 "$a ($lb)"
	    }
	}
	if {[llength $msk1] == 0} {
	    lappend msk1 "*"
	}
	
      ttk::combobox $fm.filter.entdir -width 0 -values $msk1 -textvariable ::FE::folder(filter)
      pack $fm.filter.entdir -side left -anchor w -fill both -expand 1
      eval "bind $fm.filter.entdir <<ComboboxSelected>> {[namespace current]::selectobj $fm.files.t $typew $typefb 3 $otv}"
      eval "bind $fm.filter.entdir <Key-Return> {[namespace current]::selectobj $fm.files.t $typew $typefb 3 $otv}"
      $fm.filter.entdir delete 0 end
      $fm.filter.entdir insert end [lindex $msk1 0]
      $fm.filter configure -text [mc "File filter:"] -font TkTextFont  -background "#bbf9fe"
    }

    if {$typefb == "dir"} {
      set ltit [mc "Selected directory"]
    } else {
      set ltit [mc "Selected file/directory"]
    }
    labelframe $fm.seldir -text $ltit -bd 0 -labelanchor n -font TkTextFont  -background "#bbf9fe"
    entry $fm.seldir.entdir -relief sunken -bg white -highlightthickness 0 -highlightbackground skyblue -highlightcolor blue -readonlybackground white
    pack $fm.seldir.entdir -side right -anchor ne -fill x -expand 1
    $fm.seldir.entdir configure -textvariable ::FE::folder(initialfile)
    if {$typefb != "filesave"} {
	$fm.seldir.entdir configure -state readonly
    }

    ###############=============PACK=============================
    pack $fm.titul -anchor ne -expand 0 -fill x -side top -pady {0 0}
    pack $fm.buts -anchor sw -expand 0 -fill both -side bottom

    pack $fm.tekfolder -anchor ne -expand 0 -fill x -side top
    pack $fm.seldir -anchor se -expand 0 -fill both -side bottom
    pack [ttk::separator $fm.sepbut0] -side bottom -fill x -expand 0 -pady 0
    pack $fm.filter -anchor ne -expand 0 -fill both -side bottom
    grid $fm.files.t $fm.files.y -sticky ns
    grid $fm.files.x -sticky we
    grid columnconfigure $fm.files 0 -weight 1
    grid rowconfigure $fm.files 0 -weight 1
    
    grid $fm.files.t -sticky news -padx {2 0} -pady {0 0}
#При использовании panedwindow добавляемые в панель компоненты (в данном случае $fm.fr и $fm.dirs) укаковывать (pack, greid, place) отдельно не надо
#    pack $fm.fr -fill both -expand 1 -side right -padx 0 -anchor nw
#    pack $fm.dirs -fill both -expand 1 -side left -padx 4 -anchor nw

    pack $f3 -side top -fill both -expand 1 -padx {2 2} -pady {2 2}

    ##################################################

    set ::objNewdir [page_newdir $fm $typefb]
#    $::objNewdir config -fillnormal white
    $::objNewdir config -fillbox [$::objNewdir config -stroke]
    $::objNewdir boxtext


#puts "initfe: ::FE::folder(sepfolders)=$::FE::folder(sepfolders) initdir=$initdir"
    set ::FE::folder(tek) $initdir
    lappend ::FE::folder(history) $::FE::folder(tek)
    incr [namespace current]::folder(histpos)
    gosepfolders $fm $typew $typefb
    goupdate $w $typefb

    if {$typew != "frame"} {
#puts "init_fe WINDW tkwait visibility $w"
    	tk busy hold [winfo parent $w]
	after 20
    }
    if {!$::FE::folder(details) } {  
	$fm.files.t configure -displaycolumns {}; $fm.files.t column {#0} -stretch 1 
    }
    if {$typew == "frame"} {
#Настройка внешнего вида фрейма с проводником
	$w configure -relief groove -borderwidth 3 -highlightbackground sienna \
	    -highlightcolor chocolate  -highlightthickness 3
#Размещение фреймаа с проводником по одноиу из методов pack/grid/place
	place $w -in [winfo parent $w] -x $::FE::data(-x) -y $::FE::data(-y) -relwidth $::FE::data(-relwidth) -relheight $::FE::data(-relheight) -width $::FE::data(-width) -height $::FE::data(-height)

    }
    if {$typefb == "filesave"} {
	set ::FE::folder(initialfile) $::FE::data(-initialfile)
    }
#    goupdate $w $typefb
    update
    foreach {op} $listBtn {
	set Btn "[set op]Btn"
	$data($Btn)  config -width [$data($Btn)  config -height]
#puts "feimafe=$feimage ooo=$data($Btn) height=[$data($Btn)  config -height]"
    }
if {$::FE::data(-hidden) != $::FE::folder(hiddencb)} {
$::FE::folder(hiddencbBtn) invoke
}
if {$::FE::folder(details) == 0} {
    $::FE::folder(w).files.t configure -displaycolumns {}; $::FE::folder(w).files.t column {#0} -stretch 1
} else {
    ::FE::detailedview $::FE::folder(w)
}
  }

  proc datefmt {str} {
	clock format $str -format {%d-%m-%Y %H:%M}
  }
  proc modefmt {type mode} {
	switch $type {
		file {set rc -}
		default {set rc [string index $type 0]}
	}
	binary scan [binary format I $mode] B* bits
	foreach b [split [string range $bits end-8 end] ""] \
		c {r w x r w x r w x} {
		if {$b} {append rc $c} else {append rc -}
	}
	set rc
  }
  proc detailedview {w} {
    set w "$::FE::folder(w).files.t"
    set dcol ""
    foreach col $::FE::folder(displaycolumns) {
#	if {[subst $[subst ::FE::displaycolumns\($col\)]]}  {}
	if {$::FE::displaycolumns($col) == 1}  {
	    append dcol " $col"
	}
    }
#    puts "detailedview dcol=$dcol" 
    $w configure -displaycolumns "$dcol"
    if {$dcol != ""} { 
	$w column {#0} -stretch 0 -width $::FE::folder(width0)
    } else {
	$w column {#0} -stretch 1
    }
  }
  proc gosepfolders {w typew typefb} {
set w "$::FE::folder(w)"
    set ::SelDir ""
    set ::SelFil ""

    if {$typefb == "dir"} {
	$w.files.t heading "#0" -text  [mc {Folders}]
	return
    }
    if {$typew == "frame"} { 
	set w1 $w
    } else {
	set w1 [winfo toplevel $w]
    }
    if {!$::FE::folder(sepfolders)} {
#	eval "$::FE::folder(panedwindow) forget 0"
	eval "$::FE::folder(panedwindow) forget $::FE::folder(panedir)"
	$w1.files.t heading "#0" -text "[mc {Folders and files}]"
#puts "gosepfolders 0 ::FE::folder(sepfolders)=$::FE::folder(sepfolders)"
    } else {
#	eval "$::FE::folder(panedwindow) insert 0 $::FE::folder(panedir)"
	eval "$::FE::folder(panedwindow) add $::FE::folder(panedir) -before $::FE::folder(panefile)"
	$w1.files.t heading "#0" -text  [mc {Files}]
#puts "gosepfolders 1 ::FE::folder(sepfolders)=$::FE::folder(sepfolders)"
    }
    goupdate $w $typefb
#puts "gosepfolders END"
  }
 
  proc goup {w typefb} {
    set tdir $::FE::folder(tek)
    if {$tdir == [file dirname $tdir ]} {
	return
    }
    set tdir [file dirname $tdir ]
    set rr [file readable "$tdir"]
    if {$rr == 0} {
      tk_messageBox -title "Просмотр папки" -icon info -message "Каталог не доступен (goup):\n$tdir" -parent $w
      return
    }
    if {$typefb != "filesave"} {
	set ::FE::folder(initialfile) ""
    }

    populateRoots "$w" "$tdir" $typefb
    set ::FE::folder(tek) $tdir
    lappend ::FE::folder(history) $::FE::folder(tek)
    incr ::FE::folder(histpos)
#    $::FE::folder(prevBtn) state !disabled
    $::FE::folder(prevBtn) config -state normal
    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
  }

  proc gohome {w typefb} {
    set tdir $::env(HOME)
    if {[tk windowingsystem] == "win32"} {
#Перекодируем путь из кодировки ОС
#Для MS Win это скорей всего cp1251
#	set tdir [encoding convertfrom cp1251 $tdir ]
#Заменяем обратную косую в пути на нормальную косую
	set tdir [string map {"\\" "/"} $tdir]
    }
    if {$tdir ==  $::FE::folder(tek)} {
	return
    } 
    set ::FE::folder(prev) $::FE::folder(tek)
    $::FE::folder(prevBtn) config -state normal

    set rr [file readable "$tdir"]
    if {$rr == 0} {
      tk_messageBox -title "Просмотр папки" -icon info -message "Каталог не доступен (gohome):\n$tdir" -parent $w
      return
    }
    if {$typefb != "filesave"} {
	set ::FE::folder(initialfile) ""
    }

    populateRoots "$w" "$tdir" $typefb
    set ::FE::folder(tek) $tdir
    lappend ::FE::folder(history) $::FE::folder(tek)
    incr ::FE::folder(histpos)
#    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
    columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)

  }

  proc goupdate {w typefb} {
#    set ::SelDir ""
#    set ::SelFil ""
    set tdir [lindex $::FE::folder(history) $::FE::folder(histpos)]
if {1} {
    if {$typefb != "filesave"} {
	set ::FE::folder(initialfile) ""
    }
    populateRoots "$w" "$tdir" $typefb
}
    set ::FE::folder(tek) $tdir
    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
  }

  proc goprev {w typefb} {
    incr ::FE::folder(histpos) -1
    set tdir [lindex $::FE::folder(history) $::FE::folder(histpos)]
    if {$typefb != "filesave"} {
	set ::FE::folder(initialfile) ""
    }
    populateRoots "$w" "$tdir" $typefb
    set ::FE::folder(tek) $tdir
#    $::FE::folder(nextBtn) state !disabled
    $::FE::folder(nextBtn) config -state normal
    if {$::FE::folder(histpos) == 0} {
#	$::FE::folder(prevBtn) state disabled
	$::FE::folder(prevBtn) config -state disabled
    }
    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
  }

  proc goreverse {fm typefb} {
#puts "goreverse fm=$fm typefb=$typefb ::FE::folder(reverse)=$::FE::folder(reverse)"
    set col $::FE::folder(column) 
    set direction [expr {$::FE::folder(direction) ? 0 : 1}]
    set ::FE::folder(direction) $direction
    
    [namespace current]::columnSort $fm.files.t $col $direction
  }

  proc gohiddencb {fm typew typefb otv} {
# -variable ::FE::folder(hiddencb)
    set ::FE::folder(hiddencb) [expr {1 - $::FE::folder(hiddencb)}]

    [namespace current]::selectobj $fm.files.t $typew $typefb 3 $otv
    place forget $fm.helpview; 
    if {$::FE::folder(hiddencb)} {
#	$::FE::folder(hiddencbBtn) configure -image eye_nohidden
	$::FE::folder(hiddencbBtn) config -image eye_nohidden
    } else { 
#	$::FE::folder(hiddencbBtn) configure -image fe_hiddencb
	$::FE::folder(hiddencbBtn) config -image fe_hiddencb
    }
  }
  proc gohelphiddencb {fm f1} {
    if {$::FE::folder(hiddencb)} {
	[namespace current]::helptools $fm.helpview $f1.hiddencb 1.0 "[mc {Hide hidden folders}]" ne 
    } else {
	[namespace current]::helptools $fm.helpview $f1.hiddencb 1.0 "[mc {Add hidden folders}]" ne
    } 
  }
  
  proc gonext {w typefb} {
    incr ::FE::folder(histpos)
    set tdir [lindex $::FE::folder(history) $::FE::folder(histpos)]
    if {$typefb != "filesave"} {
	set ::FE::folder(initialfile) ""
    }
    populateRoots "$w" "$tdir" $typefb
    set ::FE::folder(tek) $tdir
#    $::FE::folder(prevBtn) state !disabled
    $::FE::folder(prevBtn) config -state normal

    if {$::FE::folder(histpos) >= [llength $::FE::folder(history)] - 1} {
#	$::FE::folder(nextBtn) state disabled
	$::FE::folder(nextBtn) config -state disabled
    }
    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
  }

  proc selectobj {w typew typefb click otv} {
    if {$::FE::folder(typew) == "frame"} { 
	set w1 $::FE::folder(w)
    } else {
	set w1 [winfo toplevel $w]
    }
    set ::SelDir "[$w1.dirs.t selection]"
    set ::SelFil "[$w1.files.t selection]"

#puts "selectobj: w=$w typew=$typew typefb=$typefb click=$click otv=$otv"
    if {[winfo exists "$w1.butMenu"]} {
puts "selectobj: exists $w1.butMenu"
	return
    }
    if {$::FE::folder(typew) == "frame"} { 
	set w1 $::FE::folder(w)
    } else {
	set w1 [winfo toplevel $w]
    }
    if {$click == 3} {
      set tekdir $::FE::folder(tek)
      if {$typefb != "dir"} {
        set mask [$w1.filter.entdir get]
      } else {
        set mask "*"
      }
      set dir "$tekdir"
        populateTree $typefb $mask $w [$w insert {} end -text "$dir" \
        -values [list "$dir" directory]]
      lappend ::FE::folder(history) $::FE::folder(tek)
      if {[incr ::FE::folder(histpos)]} {
#	    $::FE::folder(prevBtn) state !disabled
	    $::FE::folder(prevBtn) config -state normal
      }
    }
    set num [$w selection]
    set titem [$w item $num -value]
#puts "selectobj: titem=$titem num=$num w=$w full=[$w item $num]"
    if {$click == 2 && ([lindex $titem 1] == "d_directory"  || [lindex $titem 1] == "directory")} {
      #Выбираем имя главного фрейма/окна
      set tekdir "[lindex $titem 0]"
      set ::FE::folder(tek) $tekdir
      if {$typefb != "dir"} {
        set mask [$w1.filter.entdir get]
      } else {
        set mask "*"
      }
#puts "tekdir=$tekdir"
      set dir "$tekdir"
#puts "selectobj dir=$dir"
      populateTree $typefb $mask $w [$w insert {} end -text "$dir" -values [list "$dir" directory]]
      set ::FE::folder(history) [lrange $::FE::folder(history) 0 $::FE::folder(histpos)]
      lappend ::FE::folder(history) $::FE::folder(tek)
      set ldir [lindex $::FE::folder(history) 0]
      foreach d $::FE::folder(history) {
        if {[lsearch -exact $ldir $d] == -1} {
    	    lappend ldir $d
        }
      }
      $w1.tekfolder.ldir configure -value $ldir
	if {[incr ::FE::folder(histpos)]} {
#		$::FE::folder(prevBtn) state !disabled
		$::FE::folder(prevBtn) config -state normal

#		set data(selectFile) ""
	}
	$::FE::folder(nextBtn) config -state disabled
    } elseif {$click == 2 && [string range [lindex $titem 1] 0 1] == "f_"} { 
      set fm [winfo toplevel $w]
      set tekdir "[lindex $titem 0]"
      set ::FE::folder(tek) $tekdir
    } elseif {$click == 3 } {
      set tekdir ""
    } else {
      set tekdir "[lindex $titem 0]"
    }
    set ::FE::folder(initialfile) "[file tail $tekdir]"
#uts "W1=$w1 W=$w"

    if {$click == 2 && [string range [lindex $titem 1] 0 1] == "f_"} {
	if {$::FE::folder(typew) == "frame"} { 
	    set fm $::FE::folder(w)
	} else {
	    set fm [winfo toplevel $w]
	}
#      set fm [winfo toplevel $w]
#puts "selectobg: fm=$fm w=$w"
      #Это очень важно выполнение в другом потоке
      after 10 [namespace current]::fereturn $typew $fm $typefb $otv
#after 100

    }
#puts "INIT_FE:columnSort=[namespace current]::columnSort  w=$w fm.fillles.t=.fe.files.t ::FE::folder(column)=$::FE::folder(column) ::FE::folder(direction)=$::FE::folder(direction)"
    [namespace current]::columnSort $w $::FE::folder(column) $::FE::folder(direction)
  }

  proc selectdir {w typew typefb click otv} {
    if {$::FE::folder(typew) == "frame"} { 
	set w1 $::FE::folder(w)
    } else {
	set w1 [winfo toplevel $w]
    }
    set ::SelDir "[$w1.dirs.t selection]"
    set ::SelFil "[$w1.files.t selection]"
    if {[winfo exists "$w1.butMenu"]} {
puts "selectdir: exists $w1.butMenu"
	return
    }

    if {!$::FE::folder(sepfolders)} {
	return
    }
    if {$::FE::folder(typew) == "frame"} { 
	set w1 $::FE::folder(w)
    } else {
	set w1 [winfo toplevel $w]
    }
    set num [$w selection]
    set titem [$w item $num -value]
#puts "selectdir titem=$titem num=$num w=$w full=[$w item $num]"
    if {$click == 2 && ([lindex $titem 1] == "d_directory" || [lindex $titem 1] == "directory")} {
      #Выбираем имя главного фрейма/окна
      set tekdir "[lindex $titem 0]"
      set ::FE::folder(tek) $tekdir
      if {$typefb != "dir"} {
        set mask [$w1.filter.entdir get]
      } else {
        set mask "*"
      }
#puts "tekdir=$tekdir"
      set dir "$tekdir"
#puts "selectdir dir=$dir"
      populateTree $typefb $mask $w1.files.t [$w1.files.t insert {} end -text "$dir" -values [list "$dir" directory]]
      set ::FE::folder(history) [lrange $::FE::folder(history) 0 $::FE::folder(histpos)]
      lappend ::FE::folder(history) $::FE::folder(tek)
      set ldir [lindex $::FE::folder(history) 0]
      foreach d $::FE::folder(history) {
        if {[lsearch -exact $ldir $d] == -1} {
    	    lappend ldir $d
        }
      }
      $w1.tekfolder.ldir configure -value $ldir
	if {[incr ::FE::folder(histpos)]} {
#		$::FE::folder(prevBtn) state !disabled
	    $::FE::folder(prevBtn) config -state normal
	}
#	$::FE::folder(nextBtn) state disabled
	$::FE::folder(nextBtn) config -state disabled
    } else {
      set tekdir "[lindex $titem 0]"
    }
    if {$typefb == "dir"} {
	$w1.seldir.entdir configure -state normal
	$w1.seldir.entdir delete 0 end
	$w1.seldir.entdir insert end "[file tail $tekdir]"
        $w1.seldir.entdir configure -state readonly

    }
    if {[$w1.dirs.t heading "#0" -text] != [mc {Folders}]} {
	[namespace current]::columnSort $w1.files.t $::FE::folder(column) $::FE::folder(direction)
    }
    
  }
    proc fedeloo {} {
#	puts "firstOO = $::FE::folder(firstOO) lastOO = $::FE::folder(lastOO)"    
	set ind0 [string range $::FE::folder(firstOO) 9 end]
	set indN [string range $::FE::folder(lastOO) 9 end]
#	puts "firstOO = $ind0 lastOO = $indN"
	while {$ind0 <= $indN} {
	    set deloo "::oo::Obj$ind0"
	    if {[catch {info object class $deloo}] == 0} {
		catch {$deloo destroy}
	    }
	    incr ind0
	}
	
	return
    }


  proc fereturn {typew w typefb otv} {
#puts "fereturn: typew=$typew w=$w typefb=$typefb otv=$otv "
    bind $w <Destroy> {}
    set num [$w.files.t selection]
    set titem [$w.files.t item $num -value]
    set ret [lindex $titem 0]
    if {$ret == ""} {
	return ""
    }
    set type [file type $ret]
#puts "TYPE=$type typefb=$typefb"
    if {$typefb == "dir" && $type != "directory"} {
#puts "Надо выбрать каталог!"
	return ""
    }
    if {$typefb != "dir" && $type != "file"} {
#puts "Надо выбрать файл!"
	return ""
    }
    variable $otv
    if {$ret == ""} {
      if {$typefb == "dir"} {
        $w.tekfolder.ldir configure -state normal
        set ret [$w.tekfolder.ldir get]
        $w.tekfolder.ldir configure -state readonly
#        set ret [file join  $::FE::folder(tek) $::FE::folder(initialfile)]
#puts "fereturn DIR ret=$ret"
      } elseif {$typefb == "filesave"} {
        if {$::FE::folder(initialfile) == ""} {
    	    return
        }
        set ret [file join  $::FE::folder(tek) $::FE::folder(initialfile)]
      } else {
        return
      }
    }

    set $otv $ret
    if {$typew != "frame"} {
	set ::Fegeo [wm geometry $w]
	catch {tk busy forget [winfo parent $w]}
    } else {
	all_busy_forget [winfo parent $w]
    }
    catch {destroy $w}
#puts "fereturn: typew=$typew w=$w typefb=$typefb otv=$otv  otv=$otv \$otv=[set [subst $otv]]"
    update
    ::FE::fedeloo
    return $otv
  }

  proc fecancel {typew w typefb otv} {
#puts "fecancel: [winfo exists .fe.butMenu]"
    bind $w <Destroy> {}
    if {$typew != "frame"} {
	set ::Fegeo [wm geometry $w]
	catch {tk busy forget [winfo parent $w]}
    } else {
	all_busy_forget [winfo parent $w]
    }
    catch {destroy $w}
    variable $otv
    set $otv ""
    ::FE::fedeloo
    return $otv
  }

  ## Code to populate the roots of the tree 
  proc populateRoots {w dir typefb} {
    global env
    set tree "$w.files.t"

    set tekdir $dir
    set w1 [winfo toplevel $tree]
#puts "populateRoots tree=$tree dir=$dir typefb=$typefb"
    if {$typefb != "dir"} {
      set mask $::FE::folder(filter)
    } else {
      set mask "*"
    }
    set dir "$tekdir"
      populateTree $typefb $mask $tree "[$tree insert {} end -text "$dir" \
      -values [list "$dir" directory]]"
#    [namespace current]::columnSort $w.files.t $::FE::folder(column) $::FE::folder(direction)
  }

  ## Code to populate a node of the tree
  proc populateTree {typefb mask tree node} {
    $tree delete [$tree children $node]
    if {$::FE::folder(typew) == "frame"} { 
	set w1 $::FE::folder(w)
    } else {
	set w1 [winfo toplevel $::FE::folder(w)]
    }
    if {$::FE::folder(sepfolders)} {
	set wtree "$w1.dirs.t"
    } else {
	set wtree $tree
    }
    if {[$tree set $node type] ne "d_directory" && [$tree set $node type] ne "directory"} {
      return
    }
    if {![llength $::FE::folder(history)]} {
	set path $::FE::folder(tek)
    } else {
	set path "[$tree set $node fullpath]"
    }
    #На первый уровень
    set node ""
    set directory_list ""

    set rr [file readable "$path"]
    if {$rr == 0} {
      tk_messageBox -title "Просмотр папки" -icon info -message "Каталог не доступен (populateTree):\n$path" -parent .
      set ::tekPATH $path
      return
    }
	if {$::FE::folder(hiddencb) > 0} {
		set pattern "* .*"
	} else {
		set pattern "*"
	}

#    if {$::FE::folder(hiddencb)} {}
#      set directory_list1 [lsort -dictionary [glob -nocomplain -types {d } -directory "$path" "*"]]

set directory_list1 [list]
if {0} {
    if {$::FE::folder(hiddencb) > 0} {
      foreach f1  [lsort [glob -nocomplain -types {d hidden} -directory "$path" "*"]] {
		if {![file isdirectory [file join $path $f1]]} continue
		lappend directory_list1 [file join $path $f1]
      }
		
    } else {
      set directory_list1 [lsort -dictionary [glob -nocomplain -types d  -directory "$path" "*"]]
    }
}
set directory_list1 [lsort [eval glob -nocomplain -types d  -directory "$path" $pattern ]]

      set ptr [string first "/.. " $directory_list1]
      if {$ptr != -1} {
        append directory_list [string range $directory_list1 [expr $ptr + 3] end ]
      } else {
        set directory_list $directory_list1
      }
#{    }
#puts "DIRECTORY_LIST=$directory_list"
    set ::tekPATH $path
    $tree delete [$tree children $node]
    set levelup [file dir $path ]
    set type [file type $levelup]
    set ind 0
    if {$::FE::folder(sepfolders)} {
	$wtree delete [$wtree children $node]
    }
    foreach f [lsort -dictionary $directory_list] {
      set typeOrig [file type "$f"]
#      set type "directory"
      set type "d_$typeOrig"
      set rr [file readable "$f"]
      if {$rr == 0} {
        set id [$wtree insert $node end -id $ind -image fe_icondirdenied -text [file tail "$f"] \
        -values [list "$f" "denied"]]
      } else {
    	if {$typeOrig == "link"} {
    	    set id [$wtree insert $node end -id $ind -image fe_folder_link -text [file tail "$f"] -values [list "$f" $type]]
    	} else {
    	    set id [$wtree insert $node end -id $ind -image fe_icondir -text [file tail "$f"] -values [list "$f" $type]]
    	}
      }
      incr ind
      if {$::FE::folder(sepfolders) == 0 } {
        file stat $f fstat
	set size $fstat(size)
	set date $fstat(mtime)
	set uid  $fstat(uid)
	set mode $fstat(mode)
	set type $fstat(type)
        $wtree set $id size $size
        $wtree set $id date [datefmt $date]
        $wtree set $id dateorig $date
        $wtree set $id permissions [modefmt $type $mode]
      }
    
    }
    if {$typefb != "dir"} {
	set files_list [list]
	set ind1 [string last "(" $mask]
	set ind2 [string last ")" $mask]
	incr ind1
	incr ind2 -1
	set mask1 [string range $mask $ind1 $ind2]
#puts "MASK1=$mask1 MAK=$mask ind1=$ind1 ind2=$ind2"
if {0} {
	foreach f1 [eval [linsert "$mask1" 0 glob -nocomplain -tails \
		-directory $path -type {f l c b p} ]] {
		# Links can still be directories. Skip those.
		if {[file isdirectory [file join $path $f1]]} continue
		lappend files_list [file join $path $f1]
	}
}
if {1} {
    if {$pattern == "*"} {
	set pattern {f l c b p}
    } else {
	set pattern {f l c b p hidden}
    }
	if {$::FE::folder(hiddencb)} {
	    foreach f1 [eval [linsert "$mask1" 0 glob -nocomplain -tails \
		-directory $path -type {f l c b p hidden}]] {
		# Links can still be directories. Skip those.
		if {[file isdirectory [file join $path $f1]]} continue
		lappend files_list [file join $path $f1]
	    }
	} 
	foreach f1 [eval [linsert "$mask1" 0 glob -nocomplain -tails \
		-directory $path -type {f l c b p} ]] {
		# Links can still be directories. Skip those.
		if {[file isdirectory [file join $path $f1]]} continue
		lappend files_list [file join $path $f1]
	}
	
	
}
#puts "FILES_LIST=$files_list"
      foreach f $files_list {
        set typeOrig [file type $f]
#        set type "file"
        set type "f_$typeOrig"
        if {$typefb == "fileopen"} {
          #Можно было бы задать -types {f r}, но тогда бы мы не увидели часть файлов в списке (denied)
          set rr [file readable $f]
        } else {
          set rr [file writable $f]
          #Можно было бы задать -types {f w}
        }
        if {$rr == 0} {
          set id [$tree insert $node end -id $ind -image fe_iconfiledenied -text [file tail $f] \
          -values [list $f "denied"]]
        } else {
    	    if {$typeOrig == "link"} {
        	set id [$tree insert $node end -id $ind -image fe_file_link -text [file tail $f] -values [list $f $type]] 
          } else {
        	set id [$tree insert $node end -id $ind -image fe_iconfile -text [file tail $f] -values [list $f $type]] 
          }
        }
        incr ind
        
        file stat $f fstat
	set size $fstat(size)
	set date $fstat(mtime)
	set uid  $fstat(uid)
	set mode $fstat(mode)
	set type $fstat(type)
        ## Format the file size nicely
        if {0} {
          if {$size >= 1024*1024*1024} {
            set size [format %.1f\ GB [expr {$size/1024/1024/1024.}]]
          } elseif {$size >= 1024*1024} {
            set size [format %.1f\ MB [expr {$size/1024/1024.}]]
          } elseif {$size >= 1024} {
            set size [format %.1f\ KB [expr {$size/1024.}]]
          } else {
            append size " bytes"
          }
        }
        $tree set $id size $size
        $tree set $id date [datefmt $date]
        $tree set $id dateorig $date
        $tree set $id permissions [modefmt $type $mode]
      }
    }

    $tree set $node type processedDirectory
  }

  proc page_newdir {fm typefb}  {
  
    set ::newname  [mc "Enter a name for new folder"]
#    ttk::label $fm.lforpas -text [mc "Enter a name for new folder"]  -textvariable ::newname

    #Widget for new Name
#    labelframe $fm.topName -borderwidth 4 -labelanchor nw -relief groove -labelwidget $fm.lforpas -foreground black -height 120 -width 200  -bg #eff0f1
    set clfr [cframe new $fm.topName -type clframe -text $::newname -width 10c]
    $clfr boxtext
    $clfr config -fillnormal yellow -fontsize 3.5m
#Поднять виджет, чтобы снять блокирование сверху
    eval "bind $fm.topName  <Configure> {$clfr resize %w %h 0;lower $fm.topName; raise $fm.topName}"
#bind $::FE::folder(w) <Configure>  {raise $::FE::folder(w) $zz._Busy }

#    set g1 [$fm.topName gradient create linear -stops {{0 "#bababa"} {1 "#454545"}} -lineartransition {0 0 0 1}]

    entry $fm.topName.entryPw -background snow  -highlightbackground gray85 -highlightcolor skyblue -justify left -relief sunken -readonlybackground snow
    pack $fm.topName.entryPw -fill x -expand 1 -padx 3m -ipady 2 -pady {6m 2m}
    eval "bind $fm.topName.entryPw <Key-Return> {[namespace current]::readName $fm.topName.entryPw}"
#    ttk::button $fm.topName.butPw  -command {global yespas;set yespas "no"; } -text [mc "Cancel"]
    set cbut [cbutton new $fm.topName.butPw -type ellipse  -text [mc Cancel]  -fillnormal red  -command {global yespas;set yespas "no"; }]
#    set g11 [$fm.topName.butPw gradient create linear -stops {{0 "#bababa"} {1 "#2adad4"}} -lineartransition {0 0 0 1}]
    set g11 [$fm.topName.butPw gradient create radial -stops {{0 "#00FFEB"} {1 "#03b1fc"}} -radialtransition {0.50 0.50 0.50 0.2 0.2}]
    $cbut config -fillnormal $g11 -fillopacity 1.0
    [$cbut canvas] configure -background [$clfr config -fillnormal]
#    eval "ttk::button $fm.topName.butOk  -command {[namespace current]::readName $fm.topName.entryPw} -text [mc Done]"
    set cbut [eval "cbutton new $fm.topName.butOk -type ellipse  -text [mc Done]  -fillnormal red  -command {[namespace current]::readName $fm.topName.entryPw}"]
    set ::FE::folder(lastOO) $cbut
#    set g11 [$fm.topName.butOk gradient create linear -stops {{0 yellow} {1 cyan}} -lineartransition {0 0 0 1}]
    set g11 [$fm.topName.butOk gradient create radial -stops {{0 "#03b1fc"} {1 "#00FFEB"}} -radialtransition {0.50 0.50 0.50 0.8 0.8}]
    $cbut config -fillnormal $g11
    [$cbut canvas] configure -background [$clfr config -fillnormal]

    pack $fm.topName.butPw $fm.topName.butOk -side right -padx 2m -pady {0 2m}
    return $clfr
  }

  proc readName ent {
    global widget
    global yespas
    global pass
    set pass [$ent get]
    $ent delete 0 end
    set yespas "yes"
  }

  proc goadddir {fm typefb} {
    createdir  "dir" $fm.tekfolder $fm $typefb
    return
  }

  proc goaddfile {fm typefb} {
    createdir  "file" $fm.tekfolder $fm $typefb
    return
  }

  proc createdir {type w fm typefb} {
    global pass
    global yespas
    if {$type == "dir"} {
      set ::newname  [mc "Enter a name for new folder"]
    } elseif {$type == "file"} {
      set ::newname  [mc "Enter a new file name"]
    } else {
      return
    }
    $::objNewdir config -text "$::newname" 
    set yespas ""
    set cnv [winfo parent [$::objNewdir canvas]]
    all_busy_hold $cnv
    set px [expr {int([winfo fpixels [$::objNewdir canvas] 0.5c])}]
    set py [expr {int([winfo fpixels [$::objNewdir canvas] 3c])}]
    $::objNewdir place -x $px -y $py -relwidth 0.9
    update
#after 20
    all_busy_forget_old $cnv
    all_busy_hold_old $cnv
    all_busy_forget_old $cnv.topName
#    lower $cnv.topName
    raise $cnv.topName
    update
#puts "createdir: cnv=$cnv"
    focus [$::objNewdir canvas].entryPw
    vwait yespas
#    tk  busy forget $cnv
    all_busy_forget_old $cnv
#    place forget $fm.topName
    place forget [$::objNewdir canvas]
    if { $yespas == "no" } {
      set pass ""
      return 0
    }
    set yespas "no"
    set newdir $pass
    set newd [file join $::tekPATH $newdir]
    if {[file exists $newd]} {
#      puts "Такое имя уже есть"
      return
    }
    if {$type == "dir"} {
	catch {file mkdir $newd} er 
	if {$er != ""} {
    	    tk_messageBox -title [mc "Create directory"] -icon info -message "Каталог создать не удалось\n$er" -parent $w
	    return
	}
	lappend ::FE::folder(history) [file join $::FE::folder(tek) $newdir]
	gonext $fm $typefb
    } else {
        if {[catch {set fd [open $newd w]} er]} {
    	    tk_messageBox -title [mc "Create file"] -icon info -message "Файл создать не удалось\n$er" -parent $w
    	    return
        }
        chan configure $fd -translation binary
        close $fd
	goupdate $fm $typefb
    }
    set pass ""
    return
  }

  proc renameobj {w typefb oldname fm} {
    global pass
    global yespas
    if {$typefb == "dir"} {
      set ::newname  [mc "Enter a new folder name"]
    } elseif {$typefb == "fileopen" || $typefb == "filesave" } {
      set ::newname  [mc "Enter a new file name"]
    } else {
      return
    }
    $::objNewdir config -text "$::newname" 
    #Перевод текста у кнопок
    set cnv [winfo parent [$::objNewdir canvas]]

    all_busy_hold_old $cnv

    $::objNewdir place -x 20 -y 100 -relwidth 0.9
update
#after 20
    all_busy_forget_old $cnv
    all_busy_hold_old $cnv
    all_busy_forget_old $cnv.topName
    lower $cnv.topName
    raise $cnv.topName
update

#    focus $fm.topName.entryPw
    focus [$::objNewdir canvas].entryPw
    set yespas ""
    vwait yespas
#    tk  busy forget $cnv
    all_busy_forget_old $cnv
#    place forget $fm.topName
    place forget [$::objNewdir canvas]
#    place forget $fm.topName
    place forget [$::objNewdir canvas]
    if { $yespas == "no" } {
      set pass ""
      return 0
    }
    set yespas "no"
    set newdir $pass
    set newd [file join $::tekPATH "$newdir"]
    set oldn [file join $::tekPATH "$oldname"]
#puts "\n$newdir\n$oldname\n$newd\n$oldn"

    if {[file exists $newd]} {
      if {$typefb == "fileopen" || $typefb == "filesave"} {
        set answer [tk_messageBox -title "mc {Rename file}" -icon question -message "Файл с таким именем есть:\n$oldname\nПродолжить операцию ?" -type yesno  -parent $w]
        if {$answer != "yes"} {
          return
        }
      }
    }
    file rename -force "[lindex $oldname 0]" "$newd"
    set ::FE::folder(initialfile) ""
    $fm.seldir.entdir configure -state normal
    $fm.seldir.entdir delete 0 end
    if {$typefb != "filesave"} {
	$fm.seldir.entdir configure -state readonly
    }
    populateRoots "$fm" "$::tekPATH" $typefb
    set pass ""
  }
  proc fe_getsavefile {args} {
    #Формируем случайную переменную
    set rand [expr int(rand() * 10000)]
    set rr "otv$rand"
    #Ответ будет создан в пространстве имен fileexplorer!!!
    variable $rr
    initfe filesave $rr $args
    set cmd [subst "vwait ::FE::$rr"]
    eval $cmd
    set ret [subst "::FE::$rr"]
    set retok [subst $$ret]
    unset $rr
    if {$::FE::folder(typew) == "frame"} {
	if {[winfo exist $::FE::folder(w)]} {
	    set w [winfo toplevel $::FE::folder(w)]
	    all_busy_forget [winfo toplevel $w]
	}
    }
    return "$retok"
  }
  proc fe_getopenfile {args} {
    #Формируем случайную переменную
    set rand [expr int(rand() * 10000)]
    set rr "otv$rand"
    #Ответ будет создан в пространстве имен fileexplorer!!!
    variable $rr
    initfe fileopen $rr $args
    set cmd [subst "vwait ::FE::$rr"]
    set w [winfo toplevel $::FE::folder(w)]
    eval $cmd
    set ret [subst "::FE::$rr"]
    set retok [subst $$ret]
    unset $rr
    if {$::FE::folder(typew) == "frame"} {
	all_busy_forget $w
    }
puts "::FE::folder(typew)=$::FE::folder(typew) w=$w"
    return "$retok"
  }
  proc fe_choosedir {args} {
    #Формируем случайную переменную
    set rand [expr int(rand() * 10000)]
    set rr "otv$rand"
    #Ответ будет создан в пространстве имен fileexplorer!!!
    variable $rr
    initfe dir $rr $args
    set cmd [subst "vwait ::FE::$rr"]
    set w [winfo toplevel $::FE::folder(w)]
    eval $cmd
    set ret [subst "::FE::$rr"]
    set retok [subst $$ret]
    unset $rr
    if {$::FE::folder(typew) == "frame"} {
	all_busy_forget [winfo toplevel  $w]
    }
    return "$retok"
  }
  proc all_disable {parent} {
    set widgets [info commands $parent*]
    foreach w $widgets {
	catch {$w configure -state disabled}
    }
  }
  proc all_enable {parent} {
    set widgets [info commands $parent*]
    foreach w $widgets {
	catch {$w configure -state normal}
    }
  }
  proc all_busy_hold {parent} {
tk busy hold $parent
return

    set widgets [info commands $parent*]
    foreach w $widgets {
	if {$w == "." } { continue}
	catch {tk busy hold $w}
    }
    catch {tk busy forget $parent}
  }
  proc all_busy_forget {parent} {
if {[tk busy status $parent]} {
    tk busy forget $parent
}
return

    set widgets [info commands $parent*]
    foreach w $widgets {
#puts "proc all_busy_forget: w=$w w_Busy=$w\_Busy"
	if {$w == "." } { continue}
	catch {tk busy forget $w}
    }
  }
  proc all_busy_hold_old {parent} {
    set widgets [info commands $parent*]
    foreach w $widgets {
	if {$w == "." } { continue}
	catch {tk busy hold $w}
    }
    catch {tk busy forget $parent}
  }
  proc all_busy_forget_old {parent} {
    set widgets [info commands $parent*]
    foreach w $widgets {
#puts "proc all_busy_forget: w=$w w_Busy=$w\_Busy"
	if {$w == "." } { continue}
	catch {tk busy forget $w}
    }
  }

  
 # С grid лучше, т.к. запоминается где был - grid remove
  proc hidescroll {sb  first last} {
    if {($first <= 0.0) && ($last >= 1.0)} {
    # Since I used the grid manager above, I will here too.
    # The grid manager is nice since it remembers geometry when widgets are hidden.
    # Tell the grid manager not to display the scrollbar (for now).
	grid remove $sb
    } else {
    # Restore the scrollbar to its prior status (visible and in the right spot).
	grid $sb
    }
    $sb set $first $last
  }

  set folder(history) ""
  set folder(histpos) -1


  namespace export fe_getsavefile
  namespace export fe_getopenfile
  namespace export fe_choosedir
  namespace export all_enable
  namespace export all_disable

}

