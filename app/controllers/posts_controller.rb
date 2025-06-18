class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
  end

  def show
    @name = params[:name]
    @title = @name
    filename = "#{@name}.md"
  end

  def new
    @hide_upload_footer = true
  end

  def create
    if params[:markdown_file].present?
      file = params[:markdown_file]
      logger.info "Received file #{file.original_filename}"

      posts_dir = Rails.root.join("app", "posts")
      FileUtils.mkdir_p(posts_dir)

      new_filename = file.original_filename.gsub(/ /, "-")
      file_path = posts_dir.join(new_filename)
      File.write(file_path, file.read)

      redirect_to "/posts/#{new_filename}"
    else
      flash.now.alert = "Please select a file"
      @hide_upload_footer = true
      render :new, status: :bad_request
    end

  rescue StandardError => e
    flash.now.alert = "Error uploading file: #{e}"
    @hide_upload_footer = true
    render :new, status: :internal_server_error
  end
end
