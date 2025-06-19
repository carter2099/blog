class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @hide_upload_footer = true
    @post = Post.new
  end

  def create
    @post = Post.new
    post_params = params.expect(post: {})
    post_params.expect(:title)
    @post.title = post_params[:title]

    if post_params[:file].present?
      file = post_params[:file]
      logger.info("Received file #{file.original_filename}")

      posts_dir = Rails.root.join("app", "posts")
      FileUtils.mkdir_p(posts_dir)
      new_filename = file.original_filename.gsub(/ /, "-")
      file_path = posts_dir.join(new_filename)
      File.write(file_path, file.read)

      @post.path = file_path
      if @post.save
        logger.info("Succesfully saved post: #{@post.inspect}")
        redirect_to @post
      else
        logger.error("Error saving post: #{@post.errors}")
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
    logger.error("Error creating post: #{e.message}")
    flash.now.alert = "Error creating post: #{e}"
    @hide_upload_footer = true
    render :new, status: :internal_server_error
  end
end
