# frozen_string_literal: true

# Low-spec VPS profile: one process, small thread pool, no preload.
worker_count = Integer(ENV.fetch("WEB_CONCURRENCY", 0))
workers worker_count if worker_count.positive?
preload_app! if worker_count.positive?

threads Integer(ENV.fetch("PUMA_MIN_THREADS", 2)),
        Integer(ENV.fetch("PUMA_MAX_THREADS", 5))

port Integer(ENV.fetch("PORT", 9292))
environment ENV.fetch("RACK_ENV", "development")
