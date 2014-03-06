class Status
  include HTTParty
  base_uri 'https://api.github.com'

  attr_reader :response, :user, :repository, :commit_hash

  def initialize(user, repository, commit_hash, options = {})
    @user        = user
    @repository  = repository
    @commit_hash = commit_hash

    options      = default_options.merge(options)

    @response    = get(get_path(user, repository, commit_hash), options)
  end

  def success?
    response.code == 200
  end

  def update(options = {})
    options = update_options.merge(options)
    [body, response_body]
    # post(update_path(user, repository, commit_hash), update_options)
  end

  def need_update?
    last_update["state"] != state
  end

private

  def status_groups
    response_body.reject { |s| s["description"].match("MultiStatus:") }.group_by { |s| s["target_url"] }
  end

  def statuses
    status_groups.map do |group, statuses|
      statuses.sort_by { |s| s["updated_at"] }.last
    end.sort_by { |s| s["updated_at"] }
  end

  def states
    @states ||= statuses.map do |status|
      status["state"]
    end
  end

  def last_update
    response_body.select { |s| s["description"].match("MultiStatus:") }.sort_by { |s| s["updated_at"] }.last
  end

  def state
    if states.any? { |s| s == "error" }
      "error"
    elsif states.any? { |s| s == "failure" }
      "failure"
    elsif states.any? { |s| s == "pending" }
      "pending"
    elsif states.any? { |s| s == "success" }
      "success"
    else
      nil
    end
  end

  def descriptions
    @descriptions ||= statuses.select { |s| s["state"] == state }.map do |status|
      status["description"]
    end
  end

  def description
    "MultiStatus: #{descriptions.join(" ")}"
  end

  def target_url
    statuses.last["target_url"]
  end

  def response_body
    JSON.load(response.body)
  end

  def default_options
    { headers: headers, basic_auth: basic_auth }
  end

  def update_options
    { headers: headers, basic_auth: basic_auth, body: body }
  end

  def body
    {
      state: state,
      target_url: target_url,
      description: description
    }
  end

  def headers
    { "User-Agent" => "MultiStatusApp" }
  end

  def get(*args)
    self.class.get(*args)
  end

  def post(*args)
    self.class.post(*args)
  end

  def basic_auth
    { username: ENV["GITHUB_CLIENT_ID"], password: ENV["GITHUB_SECRET_ID"] }
  end

  def get_path(user, repository, commit_hash)
    "/repos/#{user}/#{repository}/statuses/#{commit_hash}"
  end

  def update_path(user, repository, commit_hash)
    "/repos/#{user}/#{repository}/statuses/#{commit_hash}"
  end
end
