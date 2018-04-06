#!/usr/bin/ruby -Ku

require 'base64'

class Users
  attr_accessor :uid
  attr_accessor :cn
  attr_accessor :unum
  attr_accessor :kname
  attr_accessor :empnum
end

ary=Array.new

count=0

uid=""
cn=""
unum=""
kname=""
empnum=""
enabled=""
itemcount=0

if ARGV.size<1
  puts "Usage: prepareAccounts.rb [lif file]"
  exit
end

passwdArray=Array.new
IO.foreach("./passwd.txt"){|l|
  l.chomp!
  uid,dd=l.split(/:/)
  passwdArray.push(uid)
}


IO.foreach(ARGV[0]){|n|

  n.chomp!

  if n =~ /^uid: /
    dd,uid=n.split(/ /)
    itemcount=itemcount+1
    puts "D: uid "+uid
  end
  if n =~ /^cn: /
    dd,cn=n.split(/: /)
    itemcount=itemcount+1
    puts "D: cn "+cn
  end
  if n =~ /^uidNumber: /
    dd,unum=n.split(/ /)
    itemcount=itemcount+1
    puts "D: uidNumber "+unum
  end
  if n =~ /^cn;lang-ja:: /
    dd,kname=n.split(/ /)
    kname=Base64.decode64(kname)
    itemcount=itemcount+1
    puts "D: cn-j "+kname
  end
#  if n=~ /^uidNumber: /
#    dd,empnum=n.split(/ /)
#    itemcount=itemcount+1
#    puts "D: empnum "+empnum
#  end

  if n=~ /^komazawaEnabledFlag:/
    #komazawaEnabledFlag: enabled
    dd1,dd2=n.split(/ /)
    if dd2=="enabled"
      enabled=true
    else
      enabled=false
    end
    itemcount=itemcount+1
    puts "D: flag "+enabled.to_s
  end


  if itemcount==5
    itemcount=0
    if uid=~ /^kick/
      uid=""
      cn=""
      unum=""
      kname=""
      empnum=""
      enabled=false
      next
    end
    if !enabled
      uid=""
      cn=""
      unum=""
      kname=""
      empnum=""
      enabled=false
      puts "Disabled user: #{uid}"
      next
    end

    puts uid+" "+cn+" "+unum+" "+kname

    if !passwdArray.include?(uid)
      u=Users.new
      u.uid=uid
      u.cn=cn
      u.unum=unum
      u.kname=kname
      u.empnum=empnum
      ary.push(u)
    end

    uid=""
    cn=""
    unum=""
    kname=""
    empnum=""
    enabled=false
  end

}


Dir::mkdir("out")

#gen gmsuser sql
outf=File.new("out/gmsuser.sql","w")
ary.each{|n|
  outf.puts "INSERT INTO gmsuser (uid,stnum,ename,kname,flag) VALUES ('#{n.uid}', '#{n.unum}','#{n.cn}','#{n.kname}', 0);"
}
outf.close

#gen masterpasswd
outf=File.new("out/nis.txt","w")
ary.each{|n|
  outf.puts "#{n.uid}:x:#{n.unum}:10000:#{n.cn}:/home/#{n.uid}:/bin/bash"
}
outf.close


#gen gmp01 passwd
outf=File.new("out/gmp01.txt","w")
ary.each{|n|
  outf.puts "#{n.uid}:x:#{n.unum}:10000:#{n.cn}:/FS/sftp-chroot/home/#{n.uid}:/usr/local/bin/rssh"
}
outf.close

#gen mkhome.sh
outf=File.new("out/genhome.sh","w")
ary.each{|n|
  outf.puts "mkdir /FS/EMC/home/#{n.uid}"
  outf.puts "chown #{n.uid}:stdgm /FS/EMC/home/#{n.uid}"
}
outf.close

