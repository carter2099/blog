require "redcarpet"

class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_post, only: %i[ show edit update destroy ]

  def index
    @posts = Post.all
  end

  def show
    file = File.new(@post.path)
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        hard_wrap: true,
        filter_html: true
      ),
      fenced_code_blocks: true
    )
    @content = markdown.render(file.read).html_safe
  end

  def new
    @hide_upload_footer = true
    @post = Post.new
  end

  def create
    @post = Post.new
    post_params = validate_params

    @post.title = post_params[:title]

    if post_params[:file].present?
      file = post_params[:file]

      @post.path = process_file(file)
      if @post.save
        logger.info("Succesfully saved post: #{@post.inspect}")
        redirect_to @post
      else
        logger.error("Error saving post: #{@post.errors.full_messages}")
        flash.now.alert = "Error saving post: #{@post.errors.full_messages.join(',')}"
        render :new, status: :unprocessable_entity
      end

    else
      flash.now.alert = "Please provide a file"
      @hide_upload_footer = true
      render :new, status: :bad_request
    end

  rescue ActionController::ParameterMissing => ve
    logger.warn(ve.message)
    render :new, status: :bad_request

  rescue StandardError => e
    logger.error("Error processing post: #{e.message}")
    flash.now.alert = "Error processing post: #{e}"
    @hide_upload_footer = true
    render :new, status: :internal_server_error
  end

  def edit
  end

  def update
    post_params = validate_params

    post_update_args = { title: post_params [:title] }
    if post_params[:file].present?
      file = post_params[:file]
      post_update_args[:path] = process_file(file)
    end
    if post_params[:images].present?
      process_images(post_params[:images])
    end
    if @post.update(post_update_args)
      logger.info("Succesfully updated post: #{@post.inspect}")
      redirect_to @post
    else
      logger.error("Error updating post: #{@post.errors.full_messages}")
      flash.now.alert = "Error updating post: #{@post.errors.full_messages.join(',')}"
      render :edit, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => ve
    logger.warn(ve.message)
    render :new, status: :bad_request

  rescue StandardError => e
    logger.error("Error processing post: #{e.message}")
    flash.now.alert = "Error processing post: #{e}"
    @hide_upload_footer = true
    render :new, status: :internal_server_error
  end


  def destroy
    unless Post.where(path: @post.path).size > 1
      deleted_dir = Rails.root.join("app", "posts", "deleted")
      FileUtils.mkdir_p(deleted_dir)
      FileUtils.mv(@post.path, deleted_dir.join(File.basename(@post.path)))
    end
    @post.destroy
    redirect_to posts_path
  end

  private
    def validate_params
      post_params = params.expect(post: {})
      post_params.expect(:title)
      post_params
    end

    def set_post
      @post = Post.find(params[:id])
    end

    def process_file(file)
      logger.info("Received file #{file.original_filename}")
      posts_dir = Rails.root.join("app", "posts")
      FileUtils.mkdir_p(posts_dir)
      new_filename = file.original_filename.gsub(/ /, "-")
      file_path = posts_dir.join(new_filename)

      # -> replace obsidian images with standard md
      # Ok because my posts won't ever be that big
      # If you're seeing this and thinking, wow let me try that:
      # no
      content = file.read
      content.gsub!(/!\[\[(.+)\]\]/, '![\1](/assets/\1)')

      File.delete(file_path) if File.exist?(file_path)
      File.binwrite(file_path, content)
      file_path
    end

    def process_images(images)
      images.reject!(&:blank?)
      return unless images.size

      logger.info("Received #{images.size} image(s)")
      images_dir = Rails.root.join("app", "assets", "images")
      FileUtils.mkdir_p(images_dir)
      images.each do |image|
        image_path = images_dir.join(image.original_filename)
        File.delete(image_path) if File.exist?(image_path)
        File.binwrite(image_path, image.read)
      end
    rescue StandardError => e
      logger.error("Error processing images: #{e}")
    end
end
