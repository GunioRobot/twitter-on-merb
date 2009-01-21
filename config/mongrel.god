# run with:  god -c /path/to/gravatar.god


MERB_ROOT = "/home/deploy/repos/twitter/current"

%w{4000 4001}.each do |port|
  God.watch do |w|
    w.name = "twitter-mongrel-#{port}"
    w.interval = 30.seconds # default      
    w.start = "merb -a mongrel -c 2 -m #{MERB_ROOT} -p #{port} \
      -P #{MERB_ROOT}/log/mongrel.#{port}.pid  -d"
    w.stop = "merb -K #{port}"
#    w.restart = "merb restart -P #{MERB_ROOT}/log/mongrel.#{port}.pid"
    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds
    w.pid_file = File.join(MERB_ROOT, "log/mongrel.#{port}.pid")
    
      
 # clean pid files before start if necessary
  w.behavior(:clean_pid_file)
  
  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end
  
  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
    
    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits)
  end
  
  # restart if memory or cpu is too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.interval = 20
      c.above = 50.megabytes
      c.times = [3, 5]
    end
    
    on.condition(:cpu_usage) do |c|
      c.interval = 10
      c.above = 10.percent
      c.times = [3, 5]
    end
  end
  
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end
