root口令管理<br/>
passwdMgr.pl checkPass ALL       验证host.ini所有主机的root口令 <br/>
passwdMgr.pl checkPass 192      验证所有含192字符串的主机的root口令 <br/>
passwdMgr.pl changePass ALL      修改所有主机的root口令，并把新口令更新到host.ini,同时把口令计入passwd.history <br/>

用户增加删除<br/>
passwdMgr.pl addUser ALL   wood   在所有主机上增加wood用户<br/>
passwdMgr.pl delUser ALL   wood   在所有主机上把wood用户删除<br/>
注意在当前目录需要有该用户的公钥文件id_rsa_pub.wood<br/>

host.ini格式 <br/>
主机名，IP地址，root口令<br/>
