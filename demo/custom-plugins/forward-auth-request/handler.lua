-- /*
--  * @Author: zhaobo
--  * @Date: 2020-07-29 15:26:49
--  * @Last Modified by:   zhaobo
--  * @Last Modified time: 2020-07-29 15:26:49
--  */

local http = require "resty.http"
local resty_cookie = require "resty.cookie"
local cjson   = require "cjson"

local ForwardAuthRequestHandler = {}

ForwardAuthRequestHandler.PRIORITY = 1000

function ForwardAuthRequestHandler:header_filter(conf)
  kong.response.set_header("uripassauth", conf.whitelist)
end

function ForwardAuthRequestHandler:access(conf)
  local method = kong.request.get_method()
  if method == "OPTIONS" then
    return
  end
  -- TODO: 判断白名单路由，这个白名单下的路由不需要做鉴权
  uri_path = kong.request.get_path()
  local is_whitelist = conf.whitelist
  -- 设置方法开头，相应的配置config.prefixs里也要添加方法开头，添加后可以从path头开始匹配，配置项可优化
  -- m_path = string.lower(method)..uri_path
  if is_whitelist then
    for _, v in ipairs(conf.prefixs) do
      n, _ = string.find(v, "/")
      m = string.sub(v, 0, n - 1)
      if m == "all" then
        m_path = "all"..uri_path
      else
        m_path = string.lower(method)..uri_path
      end
      if string.match(m_path, v) then
        return
      end
    end
  end

  token = kong.request.get_header("Token")
  local cookie = resty_cookie:new()
  token = cookie:get("auth-token")
  -- 转发auth server做鉴权校验
  local body = {
    token = token,
    path = uri_path
  }
  local body = '{"token": "%s", "path": "%s"}'
  req_body = string.format(body, token, uri_path)
  kong.log(req_body)

  local client = http.new()
  assert(client:connect("auth-service.realibox.svc.cluster.local", 8080)) -- 命名空间test需要根据部署空间调整
  local res, err = client:request {
      method = "POST",
      path = "/api/v1/auth",
      body = req_body,
      headers = {
        ["Content-Type"] = "application/json",
      }
  }
  if not res then
    kong.response.exit(res.status, { message = "failed to request: "..err})
  else
    if res.status == 200 then
      -- TODO: 设置请求头用户信息
      local add_header = kong.service.request.add_header
      res_body = res:read_body()
      kong.log("res_body: "..res_body)
      add_header("Authorization", res_body)
      data = cjson.decode(res_body)

      -- 路由是/api/asset时，设置space-id，user-id
      if string.sub(uri_path, 0, 11) == "/api/asset/" then
        add_header("space-id", data["space_id"])
        add_header("user-id", data["box_user_id"])
      end

      -- 清除cookie
      kong.service.request.clear_header("Cookie")

      client:close()
    else
      kong.response.exit(res.status, { message = "auth not pass"..res:read_body()})
    end
  end
end

return ForwardAuthRequestHandler
