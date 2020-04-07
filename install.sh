prefix=/usr/local
manprefix=$prefix/share/man/man1
version=1.1

mkdir -p $prefix/bin
install -m 755 ezbuild $prefix/bin

install -m 644 config /etc/ezbuild

mkdir -p $manprefix
sed "s/VERSION/$version/g" < ezbuild.1 > $manprefix/ezbuild.1
chmod 644 $manprefix/ezbuild.1
