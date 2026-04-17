module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
    def set_current_user
      if session = find_session_by_cookie
        self.current_user = session.user
      end
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id])
    end
  end
end
