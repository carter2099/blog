desc "Copy images from app/assets/images to public/assets"
task :load_post_images do
  PostsHelper.load_post_images
end

Rake::Task["assets:precompile"].enhance do
  Rake::Task[:load_post_images].invoke
end
