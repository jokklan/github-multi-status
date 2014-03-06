class StatusesController < ApplicationController
  def create
    @status = Status.new("BenjaminMedia", "white_album", "beacf1415f934afcb0b2b70f2093c9f58d820af3")

    if @status.success? && @status.need_update?
      @status.update
    end

    render nothing: true
  end
end
