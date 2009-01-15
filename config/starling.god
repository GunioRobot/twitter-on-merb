God.watch do |w|
  w.name = 'starling'
  w.interval = 30.seconds
 
  # I do NOT specify the -d parameter which daemonizes beanstalkd.
  # I do this so God can make it a daemon for me!
  w.start = "starling -P tmp/pids/starling.pid -q tmp/starling"

  w.start_if do |start|
    start.condition(:process_running) do |p|
      p.interval = 5.seconds
      p.running = false
    end
  end
  
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 3.megabytes
    end
  end

  w.restart_if do |restart|
    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = [3, 5]
    end
  end
    
end

@apps = []
Dir["/home/deploy/repos/merb.kicks-ass.org/current/config/*.god"].each { |config| load config}
