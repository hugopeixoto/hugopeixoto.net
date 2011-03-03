
namespace :deploy do
  desc 'Rsync to local file system'
  task :local do
    SITE.local_dir.each do |k, v|
      sh "rsync -avz -delete --exclude .cairn '#{SITE.output_dir}/#{k}/' '#{v}'"
    end
  end
end
