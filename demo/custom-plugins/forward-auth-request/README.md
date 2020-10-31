# 鉴权转发插件

# 插件使用声明
konghq.com/plugins: forward-auth-request

# 白名单路由
处于白名单下的路由前缀可以绕过鉴权，在forward-auth-request.yaml清单下配置prefixs
```
prefixs:
  - "get/api/cms/api/v4/scenes/[0-9a-z]+/public/info"
  - "all/api/plugins/3d%-atlas/"
  - "get/api/cms/api/v4/share"
  - "all/api/cms/api/cms/v1/project/visit_records"
  - "all/api/cms/api/v4/production/"
  - "get/api/cms/api/ui_editor/v1/applications/publish"
  - "get/api/cms/api/v4/scenes/publish/[0-9a-z]+"
  - "get/api/cms/api/v4/scenes/public/[0-9a-z]+"
  - "all/api/cms/api/operation/"
  - "all/api/cms/api/admin/"
  - "all/api/cms/api/app/"
  - "all/api/cms/api/content/"
  - "all/api/open/api/v1/manage/"
  - "all/api/open/api/dev/"
  - "post/api/open/api/v1/oss_callback"
  - "get/api/asset/api/scene/[0-9a-z]+/publish"
  - "get/api/asset/api/project/[0-9a-z]+/publish"
  - "post/api/cms/api/v4/oss_callback"
  - "post/api/cms/api/ui_editor/v1/oss_callback"
  - "post/api/cms/api/v4/cloud_callback"
  - "post/api/cms/api/v4/cloud_callback/publish"
  - "all/api/cms/api/client/"
  - "all/api/order/api/admin/"
  - "all/api/package/api/admin/"
  - "all/api/asset/api/callback/"
```
# 特殊处理路由
asset_editor_service 路由：/api/asset/ 处理：设置请求头space-id，user-id
Why：为了兼容它们的旧接口，要在请求头设置user-id和space-id ,然后在插件里做了这个处理。