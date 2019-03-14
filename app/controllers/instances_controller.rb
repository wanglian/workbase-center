class InstancesController < ApplicationController

  def index
    @instances = Instance.page params[:page]
  end

  def new
    @instance = Instance.new
  end

  def create
    @instance = Instance.new instances_params
    if @instance.save
      redirect_to instances_path
    else
      render 'new'
    end
  end

  def edit
    @instance = Instance.find params[:id]
  end

  def update
    @instance = Instance.find params[:id]
    if @instance.update_attributes instances_params
      redirect_to instances_path
    else
      render 'edit'
    end
  end

  def destroy
    @instance = Instance.find params[:id]
    if @instance.destroy
      redirect_to instances_path
    end
  end

  private
  def instances_params
    params.require(:instance).permit(:server_url, :company)
  end

end