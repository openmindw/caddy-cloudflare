

# --- 依赖项安装 ---
echo ">>> 步骤 1: 检测包管理器并安装依赖项 (curl, jq)..."
PKG_MANAGER=""
INSTALL_CMD=""

if command -v apt-get &> /dev/null; then
  PKG_MANAGER="apt"
  INSTALL_CMD="apt-get install -y"
  # 在 Debian/Ubuntu 上，先更新包列表
  echo "检测到 Debian/Ubuntu (apt)。正在更新包列表..."
  apt-get update
elif command -v dnf &> /dev/null; then
  PKG_MANAGER="dnf"
  INSTALL_CMD="dnf install -y"
  echo "检测到 Fedora/RHEL (dnf)..."
elif command -v yum &> /dev/null; then
  PKG_MANAGER="yum"
  INSTALL_CMD="yum install -y"
  echo "检测到 CentOS/RHEL (yum)..."
elif command -v pacman &> /dev/null; then
  PKG_MANAGER="pacman"
  # Pacman 需要非交互式参数
  INSTALL_CMD="pacman -S --noconfirm"
  echo "检测到 Arch Linux (pacman)..."
else
  echo "错误：无法识别的包管理器。请手动安装 'curl' 和 'jq' 后再运行此脚本。" >&2
  exit 1
fi

# 检查并安装 curl 和 jq
for pkg in curl jq; do
  if ! command -v "$pkg" &> /dev/null; then
    echo "正在安装 '$pkg'..."
    ${INSTALL_CMD} ${pkg}
  else
    echo "'$pkg' 已安装。"
  fi
done

# 检查 Go 是否可用，如果可用则优先使用 xcaddy 构建带 Cloudflare DNS 插件的 Caddy
GO_AVAILABLE=false
if command -v go &> /dev/null; then
  GO_AVAILABLE=true
  echo "✅ 检测到 Go 环境，将构建带 Cloudflare DNS 插件的 Caddy。"
else
  echo "⚠️  未检测到 Go 环境，将下载官方预构建版本（不含 DNS 插件）。"
  echo "   如需 Cloudflare DNS 支持，请先安装 Go 1.18+ 后重新运行此脚本。"
fi

# --- 自动检测架构和最新版本 ---
echo ""
echo ">>> 步骤 2: 检测系统架构和 Caddy 最新版本..."

case "$(uname -m)" in
  x86_64) ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
  armv6l | armv7l) ARCH="armv7" ;;
  *)
    echo "错误：不支持的系统架构: $(uname -m)" >&2
    exit 1
    ;;
esac
echo "检测到系统架构: $ARCH"

# Check if Go is available for xcaddy
if [ "$GO_AVAILABLE" = true ]; then
  echo ">>> 使用 xcaddy 构建带 Cloudflare DNS 插件的 Caddy..."
  
  # Install xcaddy if not present
  if ! command -v xcaddy &> /dev/null; then
    echo ">>> 安装 xcaddy..."
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
    # Add Go bin to PATH if not already there
    export PATH=$PATH:$(go env GOPATH)/bin
  fi
  
  echo ""
  echo ">>> 步骤 3: 使用 xcaddy 构建带 Cloudflare DNS 插件的 Caddy..."
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  
  # Build Caddy with Cloudflare DNS plugin
  xcaddy build --with github.com/caddy-dns/cloudflare
  
  if [ ! -f "caddy" ]; then
    echo "错误：xcaddy 构建失败。" >&2
    exit 1
  fi
  
  echo "将带 Cloudflare DNS 插件的 Caddy 可执行文件移动到 /usr/local/bin/..."
  mv caddy /usr/local/bin/
  chown root:root /usr/local/bin/caddy
  chmod +x /usr/local/bin/caddy

  cd ..
  rm -rf "$TMP_DIR"
  
  echo "✅ 已成功安装带 Cloudflare DNS 插件的 Caddy"

 

# --- 创建用户和目录 ---
echo ""
echo ">>> 步骤 4: 创建 Caddy 用户、组和所需目录..."
if ! getent group caddy > /dev/null; then
  echo "创建 'caddy' 组..."
  groupadd --system caddy
fi
if ! id caddy > /dev/null 2>&1; then
  echo "创建 'caddy' 用户..."
  useradd --system --gid caddy  --shell /usr/sbin/nologin caddy
fi

mkdir -p /etc/caddy
chown -R root:caddy /etc/caddy
mkdir -p /var/lib/caddy
chown -R caddy:caddy /var/lib/caddy


# 新增：创建配置目录并修复权限
mkdir -p /home/caddy/.config/caddy
chown -R caddy:caddy /home/caddy


# --- 设置 systemd 服务 ---
echo ""
echo ">>> 步骤 5: 设置 Caddy 的 systemd 服务..."
cat <<EOF > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/caddy.json --resume
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/caddy.json --resume
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# --- 创建默认配置文件 ---
echo ""
echo ">>> 步骤 6: 创建一个默认的 caddy.json..."
if [ ! -f /etc/caddy/caddy.json ]; then
cat <<EOF > /etc/caddy/caddy.json
{
  "apps": {
    "http": {
      "servers": {
        "srv0": {
          "listen": [
            ":80",
            ":443"
          ],
          "protocols": [
            "h1",
            "h2"
          ],
          "routes": []
        }
      }
    },
    "tls": {
      "automation": {}
    }
  }
}
EOF
chown caddy:caddy /etc/caddy/caddy.json
chmod 644 /etc/caddy/caddy.json
fi

# --- 启动服务 ---
echo ""
echo ">>> 步骤 7: 重新加载 systemd 并启动 Caddy 服务..."
systemctl daemon-reload
systemctl enable --now caddy

# --- 验证 ---
echo ""
echo ">>> 步骤 8: 验证安装..."
sleep 2 # 稍等片刻以确保服务完全启动

if ! command -v caddy &> /dev/null; then
    echo "错误：Caddy 安装失败，找不到命令。" >&2
    exit 1
fi

echo "Caddy 安装成功！"
caddy version

echo ""
echo "Caddy 服务状态："
systemctl status caddy --no-pager | cat # 使用 cat 防止在脚本中分页

echo ""
echo -e "\033[32m安装完成！\033[0m"
echo "您可以通过访问 http://<您的服务器IP> 来测试默认页面。"
echo "配置文件位于 /etc/caddy/Caddyfile。"
echo "修改配置后，请运行 'sudo systemctl reload caddy' 应用更改。"

# Check if Cloudflare DNS plugin was installed
if [ "$GO_AVAILABLE" = true ]; then
  echo ""
  echo -e "\033[33m重要提示：Cloudflare DNS 插件支持\033[0m"
  echo "已安装带 Cloudflare DNS 插件的 Caddy。要启用自动 HTTPS 证书："
  echo "1. 获取 Cloudflare API Token（需要 DNS 编辑权限）"
  echo "2. 设置环境变量：export CADDY_CF_TOKEN=\"your-cloudflare-token\""
  echo "3. 在 Caddyfile 中使用 tls 指令：tls {"
  echo "     dns cloudflare {env.CADDY_CF_TOKEN}"
  echo "   }"
  echo ""
  echo "更多信息请参考："
  echo "- Caddy 文档: https://caddyserver.com/docs/"
  echo "- Cloudflare DNS 插件: https://github.com/caddy-dns/cloudflare"
fi

exit 0