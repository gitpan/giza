  if($pid = fork) {
    # parent
	print STDERR "$$: i'm parent\n";
    until(waitpid $pid, 0 == -1) {};
	print STDERR "$$: child $pid finished\n";
  }
  else {
    # child
    exec('echo $$: zzZzzzZZ 2>/dev/stderr; sleep 3; echo $$: yiiiaahoooaao > /dev/stderr');
  }
