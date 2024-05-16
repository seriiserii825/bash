  cat <<TEST >> "$api_layout_path"
    import {axiosInstance} from "../axios/axios-instance";
    export async function apiLayout() {
        const data = await axiosInstance.get('/login', {
            error_alert: "apiLayout"
        });
        return {data: data};
    }
TEST
