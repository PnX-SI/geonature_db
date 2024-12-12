docker_tag_exists () {
    docker manifest inspect "postgis/postgis:$1" >/dev/null;
    echo $?


}

docker_tag_exists $1