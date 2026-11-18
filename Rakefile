# frozen_string_literal: true

require "rake"
require "fileutils"
require "rspec/core/rake_task"

ENV["RACK_ENV"] ||= "development"
require_relative "config/boot"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run model/service/policy/serializer/job/lib/db specs"
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.pattern = "spec/{models,services,policies,serializers,jobs,lib,db}/**/*_spec.rb"
  end

  desc "Run request specs (API + dashboard)"
  RSpec::Core::RakeTask.new(:request) do |task|
    task.pattern = "spec/requests/**/*_spec.rb"
  end
end

task default: :spec

# --- Development servers ------------------------------------------------------

desc "Run the app in development on PORT (default 9292)"
task :dev_up do
  sh({ "RACK_ENV" => "development", "PORT" => ENV.fetch("PORT", "9292") },
     "bundle exec puma -C config/puma.rb")
end

desc "Run the app in test mode on PORT (default 9293)"
task :test_up do
  sh({ "RACK_ENV" => "test", "PORT" => ENV.fetch("PORT", "9293") },
     "bundle exec puma -C config/puma.rb")
end

desc "Run the app in production mode on PORT (default 9294)"
task :prod_up do
  sh({ "RACK_ENV" => "production", "PORT" => ENV.fetch("PORT", "9294") },
     "bundle exec puma -C config/puma.rb")
end

desc "Open IRB with the app booted"
task :dev_irb do
  sh({ "RACK_ENV" => "development" }, "bundle exec irb -r ./config/boot")
end

# --- Database tasks -----------------------------------------------------------

def sql_string(value)
  "'#{value.gsub("'", "''")}'"
end

namespace :db do
  desc "Run pending migrations on the main database"
  task :migrate do
    result = MyErp::DB.migrate!(MyErp::DB.main, MyErp::DB::MAIN_MIGRATIONS)
    puts result == :empty ? "main: no migrations yet" : "main: migrated"
  end

  namespace :tenants do
    desc "Create a tenant database: rake 'db:tenants:create[slug]'"
    task :create, [:id] do |_task, args|
      id = args[:id].to_s
      abort "usage: rake 'db:tenants:create[slug]'" if id.empty?
      abort "invalid tenant id: #{id.inspect}" unless MyErp::DB.tenant_id?(id)

      path = MyErp::DB.tenant_path(id)
      abort "tenant '#{id}' already exists: #{path}" if File.exist?(path)

      db = MyErp::DB.connect(path)
      begin
        MyErp::DB.migrate!(db, MyErp::DB::TENANT_MIGRATIONS)
      ensure
        db.disconnect
      end

      puts "created tenant #{id}: #{path}"
    end

    desc "Run pending migrations on every tenant database"
    task :migrate do
      ids = MyErp::DB.tenant_ids
      if ids.empty?
        puts "no tenant databases found under #{File.join(MyErp::DB::DIR, "tenants")}"
        next
      end

      ids.each do |id|
        db = MyErp::DB.connect(MyErp::DB.tenant_path(id))
        begin
          MyErp::DB.migrate!(db, MyErp::DB::TENANT_MIGRATIONS)
        ensure
          db.disconnect
        end
        puts "tenant #{id}: ok"
      end
    end

    desc "Backup main + all tenant databases (VACUUM INTO db/backups/<timestamp>)"
    task :backup do
      stamp = Time.now.strftime("%Y%m%d-%H%M%S")
      target_dir = File.join(MyErp::DB::DIR, "backups", stamp)
      FileUtils.mkdir_p(target_dir)

      sources = { "main" => File.join(MyErp::DB::DIR, "main.sqlite3") }
      MyErp::DB.tenant_ids.each { |id| sources[id] = MyErp::DB.tenant_path(id) }

      sources.each do |label, source|
        unless File.exist?(source)
          puts "#{label}: skipped (missing)"
          next
        end

        db = MyErp::DB.connect(source)
        begin
          destination = File.join(target_dir, "#{label}.sqlite3")
          db.run("VACUUM INTO #{sql_string(destination)}")
          puts "#{label}: #{destination} (#{File.size(destination)} bytes)"
        ensure
          db.disconnect
        end
      end
    end
  end
end
