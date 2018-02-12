#!/usr/bin/perl
################################################################
#  passwdMgr.pl -> changePass.exp
#  passwdMgr.pl -> checkPass.exp
#  passwdMgr.pl -> userMgr.exp->userMgr.sh
################################################################
use strict;
use warnings;
use File::Spec;
use Env;
my $path_curf = File::Spec->rel2abs(__FILE__);
my ($vol, $path, $file) = File::Spec->splitpath($path_curf);


my $timeout = 30;
my $MAXPROC = 21;
if(scalar(@ARGV)<2){
        print "Usage: $0 checkPass ALL|string\n";
        print "Usage: $0 changePass ALL|string\n";
        print "Usage: $0 addUser  ALL|string userName\n";
        print "Usage: $0 delUser  ALL|string userName\n";
        exit 0;
}
my $method = $ARGV[0];
my $pattern = $ARGV[1];
my $start = time;
if(!open(FILE,'host.ini')){
        print "open host.ini failed\n";
        return -1;
}
my @lines = <FILE>;
close(FILE);
my %ipName=();
my %ipPass=();

my $lockFile = 'counter.lock';
print "Start: Lock file is: $lockFile\n";
my $procs = scalar(@lines);
if(-e "$lockFile"){
        print "有其他人在执行本操作,否则请删除$lockFile文件\n";
        exit(-1);
}
my $newRootPass = `openssl rand 15 -base64`;
my $timeStamp = localtime(time);
chomp($newRootPass);
my @pids = ();
my $procNum = 0;
for (my $i=0; $i < $procs ;$i++) {
        my $line = $lines[$i];
        chomp($line);
	next if($line =~ /^#/);
        my ($name,$ip,$rootPass) = split /,/,$line;
	$ipName{$ip} = $name;
	$ipPass{$ip} = $rootPass;
	if(defined $pattern && $pattern !~ /ALL/){
		next if ($line !~ /$pattern/);
	}
        my $cmd;
        my $sshCmd;
	my $retPipe = pipe(READPIPE,WRITEPIPE);
        my $pid = fork();
        if($pid == 0){
		close(READPIPE);
                if($method eq 'checkPass'){
                        shift(@ARGV);
                        $cmd = join ' ',@ARGV;
                        $sshCmd = "./checkPass.exp $ip  $rootPass";
                }elsif($method eq 'delUser'){
                        my $user = $ARGV[2];
			$sshCmd = "./userMgr.exp $ip $rootPass $user del";
                }elsif($method eq 'addUser'){
                        my $user = $ARGV[2];
			if(! -e "id_rsa_pub.$user"){
				print "pls. provide $user public key file:  id_rsa_pub.$user\n";
				exit(1);
			}
                        $sshCmd = "scp -rp  -o 'StrictHostKeyChecking no' -o ConnectTimeout=$timeout id_rsa_pub\.$user $ip:/tmp/ 2>error.log";
			`$sshCmd`;
                        $sshCmd = "scp -rp  -o 'StrictHostKeyChecking no' -o ConnectTimeout=$timeout userMgr.sh $ip:/tmp/ 2>error.log";
			`$sshCmd`;
			$sshCmd = "./userMgr.exp $ip $rootPass $user add";
                }elsif($method eq 'changePass'){
			$cmd = $ARGV[1];
			$sshCmd = "./changePass.exp  $ip $rootPass $newRootPass"; 
			if(open(FILE2,">>passwd.history")){
				print FILE2  "$name,$ip,$rootPass,$newRootPass,".$timeStamp."\n";
				close(FILE2);
			}
		}else{
			next;
		}
                my @out;
                @out  = `$sshCmd`;
		if($? != 0){
               		print $sshCmd."   error=$?\n";
		}
        	while(-f "$lockFile"){
        		select(undef,undef,undef,0.1);
        	}
		open(LOCKFILE,">$lockFile");
                my $count = 0;
                foreach my $inLine (@out) {
                        print WRITEPIPE "$name $ip:  $inLine";
                        $count++;
                }
		close(LOCKFILE);
		unlink("$lockFile");
                exit 0;
        }else{
		close(WRITEPIPE);
		my $line;
		while($line = <READPIPE>){
			if($line =~ /output/){
				print $line;
			}
			if($line =~ /changePass succeed/){
				my ($aa,$output,$ip,$pass) = split /:/, $line;
					$ipPass{$ip} = $pass;
			}
		}
                $procNum++;
                push(@pids,$pid);
        }
        if($procNum >= $MAXPROC ){
                foreach my $pid (@pids){
                         waitpid($pid,0);
                }
                $procNum = 0;
                @pids = ();
        }
}
        foreach my $pid (@pids){
                     waitpid($pid,0);
        }
my $elapse=time()-$start;
if(open(FILE,">host.ini")){
	foreach my $key (sort keys %ipPass){
		print FILE "$ipName{$key},$key,$ipPass{$key}\n";
	}
	close(FILE);
}
print "End, elapse $elapse secondes\n";
