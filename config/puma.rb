threads_count = ENV.fetch('RAILS_MAX_THREADS', 3)
threads threads_count, threads_count

if ENV['PUMA_SOCKET']
  bind "unix://#{ENV.fetch('PUMA_SOCKET')}"
else
  port ENV.fetch('PORT', 4743)
end

plugin :tmp_restart

plugin :solid_queue if ENV['SOLID_QUEUE_IN_PUMA']

pidfile ENV['PIDFILE'] if ENV['PIDFILE']
