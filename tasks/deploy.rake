
namespace :deploy do
  desc 'Rsync to local file system'
  task :local do
    sh "rsync -avz -delete --exclude .cairn #{SITE.output_dir}/ #{SITE.local_dir}"
  end
end
