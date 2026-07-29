# Aegis demo: Sinatra + session login. Target for scanner pipelines.
require "sinatra"
require "json"
require "securerandom"
require "rack/auth/basic"

set :bind, "0.0.0.0"
set :port, (ENV["PORT"] || 4567).to_i
enable :sessions
set :session_secret, ENV["SESSION_SECRET"] || SecureRandom.hex(32)

USERS = { "demo@example.com" => "demo1234" }.freeze
ITEMS = [
  { id: 1, name: "Widget",   price: 19.99 },
  { id: 2, name: "Gadget",   price: 24.50 },
  { id: 3, name: "Sprocket", price:  8.75 }
].freeze

helpers do
  def require_login!
    redirect "/login" unless session[:email]
  end
end

get "/" do
  "<h1>Aegis demo (Ruby)</h1><a href='/login'>Sign in</a>"
end

get "/login" do
  erb :login, locals: { error: nil }
end

post "/login" do
  email = params["email"].to_s
  password = params["password"].to_s
  if USERS[email] == password
    session[:email] = email
    redirect "/dashboard"
  else
    status 401
    erb :login, locals: { error: "Invalid credentials" }
  end
end

get "/dashboard" do
  require_login!
  erb :dashboard, locals: { email: session[:email], items: ITEMS }
end

post "/logout" do
  session.clear
  redirect "/"
end

get "/api/items" do
  content_type :json
  if session[:email]
    { items: ITEMS }.to_json
  else
    status 401
    { error: "unauthorized" }.to_json
  end
end

# ---------------------------------------------------------------------------
# HTTP Basic realm. The session login above covers ZAP's `browser` and `form`
# authentication; this is the only target in the demo estate for `http` auth,
# which is scoped to a host and port rather than to a URL.
# ---------------------------------------------------------------------------
helpers do
  def basic_authorized?
    auth = Rack::Auth::Basic::Request.new(request.env)
    return false unless auth.provided? && auth.basic? && auth.credentials
    email, password = auth.credentials
    USERS[email] == password
  end
end

before "/basic/*" do
  unless basic_authorized?
    headers["WWW-Authenticate"] = 'Basic realm="aegis-demo"'
    halt 401, { error: "unauthorized" }.to_json
  end
end

get "/basic/items" do
  content_type :json
  { items: ITEMS }.to_json
end

get "/basic/profile" do
  content_type :json
  { email: Rack::Auth::Basic::Request.new(request.env).credentials.first }.to_json
end

get "/healthz" do
  content_type :json
  { status: "ok" }.to_json
end

__END__

@@login
<!doctype html>
<title>Login</title>
<h1>Sign in</h1>
<% if error %><p style="color:red"><%= error %></p><% end %>
<form method="post" action="/login">
  <label>Email <input name="email" type="email" required></label><br>
  <label>Password <input name="password" type="password" required></label><br>
  <button type="submit">Sign in</button>
</form>

@@dashboard
<!doctype html>
<title>Dashboard</title>
<h1>Welcome, <%= email %></h1>
<ul><% items.each do |i| %><li><%= i[:name] %> — $<%= i[:price] %></li><% end %></ul>
<form method="post" action="/logout"><button>Sign out</button></form>
