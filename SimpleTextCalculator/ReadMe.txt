$1400-$1401  : ilk sayinin integer kismini tutar
$1402        : ilk sayinin decimal kismini tutar
$1403-$1404  : ikinci sayinin integer kismini tutar
$1405        : ikinci sayinin decimal kismini tutar
$1406        : aritmatik islemi tutar '+' veya '-'


*iki sayinin toplami 65535 i geçtigi durumlarda PORTB'ye FF yüklenir.
*küçük sayidan büyük sayi çikarilirsa çikarma sonucu yine pozitif olarak tutuluyor.
 Örnegin: 15.66 - 25.76 isleminin sonucu :
 -10,10 hafizada asagidaki gibi tutulur
 000A--->$1500-$15001  integer part
 0A----->$1502   decimal part

String "interger.decimal + integer2.decimal2=" seklinde operatorün saginda ve solunda
bir bosluk olacak sekilde yazilmalidir. decimal2 kismdan sonra bosluk kullanilabilir.
Diger kisimlarda bosluk kullanilmamalidir.
                               