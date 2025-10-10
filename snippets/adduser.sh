create_initra_app_user() {
    local APP_NAME="$1"
    local BASE_DIR="/home/initra"
    local APP_HOME="$BASE_DIR/$APP_NAME"

    # make base dir
    mkdir -p "$BASE_DIR"

    # create user if missing
    if ! id -u "$APP_NAME" >/dev/null 2>&1; then
        useradd -m -d "$APP_HOME" -s /usr/sbin/nologin "$APP_NAME"
        echo "created user $APP_NAME"
    fi

    # ensure home exists with perms
    mkdir -p "$APP_HOME"
    chown -R "$APP_NAME:$APP_NAME" "$APP_HOME"
    chmod 750 "$APP_HOME"

    echo "ready: $APP_NAME -> $APP_HOME"
}
# create_initra_app_user "dcts"
