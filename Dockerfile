# 基础镜像（严格保持PHP 7.2-fpm）
FROM php:7.2-fpm

# 1. 修正Debian源（解决PHP 7.2依赖的签名过期问题）
RUN sed -i 's|deb http://deb.debian.org/debian|deb [trusted=yes] http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|deb http://security.debian.org/debian-security|deb [trusted=yes] http://archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i 's|deb http://deb.debian.org/debian buster-updates|deb [trusted=yes] http://archive.debian.org/debian buster-updates|g' /etc/apt/sources.list

# 2. 安装系统依赖（增加了 curl 相关的库，这是解决问题的关键）
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 3. 安装PHP扩展（增加了 curl 扩展）
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) \
    gd \
    pdo_mysql \
    mysqli \
    mbstring \
    zip \
    exif \
    opcache \
    curl

# 4. 设置工作目录
WORKDIR /var/www

# 5. 复制项目文件
COPY . .

# 6. 修正权限（合并指令，减少镜像层数）
RUN chown -R www-data:www-data /var/www && \
    find /var/www -type f -exec chmod 644 {} \; && \
    find /var/www -type d -exec chmod 755 {} \; && \
    mkdir -p /var/www/runtime && \
    chmod -R 777 /var/www/runtime

# 7. 复制Nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

# 8. 验证Nginx配置
RUN nginx -t

# 9. 暴露端口
EXPOSE 80

# 10. 启动服务
CMD sh -c "php-fpm -D && nginx -g 'daemon off;'"
