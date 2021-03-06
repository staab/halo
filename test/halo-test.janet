(import build/halo :as halo)


(defn logger
  "Creates a logging middleware"
  [handler]
  (fn [req]
    (def start-clock (os/clock))
    (def {:uri uri
          :method method} req)
    (def ret (handler req))
    (def end-clock (os/clock))
    (def elapsed (string/format "%.3f" (* 1000 (- end-clock start-clock))))
    (def status (or (get ret :status) 200))
    (print method " " status " " uri " elapsed " elapsed "ms")
    ret))


(defn static-files [handler &opt root]
  (default root ".")
  (fn [request]
    (let [response (handler request)]
      (if (not= 404 (get response :status))
        response
        (let [{:method method :uri uri} request]
          (if (some (partial = method) ["GET" "HEAD"])
            {:file (string root uri)}
            {:status 500 :body "Internal server error" :headers {"Content-Type" "text/plain"}}))))))


(defn router
  "Creates a router middleware"
  [routes]
  (fn [request]
    (let [{:uri uri :method method} request
          handler (get routes [method uri])]
      (if (nil? handler)
        {:status 404 :body "" :headers {"Content-Type" "text/plain"}}
        (handler request)))))


(defn home [request]
  {:status 200 :body "hello from halo" :headers {"Content-Type" "text/plain"}})


(defn form [request]
  {:status 200
   :body "<!doctype html><html><head><meta charset=\"utf-8\"></head><body>
      <h1>Is a thing.</h1>
      <form action=\"/form\" method=\"post\">
        <input type=\"text\" name=\"firstname\">
        <input type=\"text\" name=\"lastname\">
        <input type=\"submit\" value=\"Submit\">
      </form>
    </body></html>"
   :headers {"Content-Type" "text/html; charset=utf-8"}})


(defn post-form [request]
  {:status 200
   :body (string "<!doctype html><html><body>
      <h1>Form submitted with " (get request :body) " </h1>
    </body></html>")
   :headers {"Content-Type" "text/html; charset=utf-8"}})


(defn redirect [request]
  {:status 302
   :headers {"Location" "/"}})


(def routes
  {["GET" "/"] home
   ["GET" "/form"] form
   ["POST" "/form"] post-form
   ["GET" "/redirect"] redirect})


(def app (-> (router routes)
             (static-files)
             (logger)))


(halo/server app 8080)
