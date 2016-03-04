class Spree::Admin::ErrorLogsController < Spree::Admin::BaseController
  # GET /spree/error_logs
  # GET /spree/error_logs.json
  def index
    @spree_error_logs = Spree::ErrorLog.order("created_at DESC")
    @spree_error_logs =  Kaminari.paginate_array(@spree_error_logs).page(params[:page]).per(15)    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @spree_error_logs }
    end
  end

  # GET /spree/error_logs/1
  # GET /spree/error_logs/1.json
  def show
    @spree_error_log = Spree::ErrorLog.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @spree_error_log }
    end
  end

  # GET /spree/error_logs/new
  # GET /spree/error_logs/new.json
  def new
    @spree_error_log = Spree::ErrorLog.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @spree_error_log }
    end
  end

  # GET /spree/error_logs/1/edit
  def edit
    @spree_error_log = Spree::ErrorLog.find(params[:id]) 
  end

  # POST /spree/error_logs
  # POST /spree/error_logs.json
  def create
    @spree_error_log = Spree::ErrorLog.new(params[:error_log])

    respond_to do |format|
      if @spree_error_log.save
        format.html { redirect_to @spree_error_log, notice: 'Erro log was successfully created.' }
        format.json { render json: @spree_error_log, status: :created, location: @spree_error_log }
      else
        format.html { render action: "new" }
        format.json { render json: @spree_error_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /spree/error_logs/1
  # PUT /spree/error_logs/1.json
  def update
    @spree_error_log = Spree::ErrorLog.find(params[:id])

    respond_to do |format|
      if @spree_error_log.update_attributes(params[:error_log])
        format.html { redirect_to admin_error_logs_path, notice: 'Erro log was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @spree_error_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /spree/error_logs/1
  # DELETE /spree/error_logs/1.json
  def destroy
    @spree_error_log = Spree::ErrorLog.find(params[:id])
    @spree_error_log.destroy

    respond_to do |format|
      format.html { redirect_to admin_error_logs_path }
      format.json { head :no_content }
    end
  end
end
