module PostsHelper
  def self.load_post_images
    if !defined?(logger)
      logger = Logger.new($stdout)
    end
    src = Rails.root.join("app", "assets", "images")
    dest = Rails.root.join("public", "assets")
    FileUtils.cp_r("#{src}/./", dest, verbose: true)
  rescue StandardError => e
    logger.error("Error during load_post_images: #{e}")
    raise
  end
end
