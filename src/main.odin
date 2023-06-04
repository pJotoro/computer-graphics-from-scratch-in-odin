package main

import "app"
import "core:slice"
import "core:math"
import "core:math/linalg"

import gl "vendor:OpenGL"

Vector2f32 :: linalg.Vector2f32
Vector3f32 :: linalg.Vector3f32
Vector4f32 :: linalg.Vector4f32
INF_F32 :: math.INF_F32

Camera :: struct {
    using position: Vector3f32,
}

Viewport :: struct {
    width, height, distance: f32,
}

screen_to_viewport :: proc "contextless" (viewport: Viewport, sx, sy: int) -> (ray: Vector3f32) {
    ray.x = f32(sx) * viewport.width / f32(app.width())
    ray.y = f32(sy) * viewport.height / f32(app.height())
    ray.z = viewport.distance
    return
}

Light :: union {
    Ambient_Light,
    Point_Light,
    Directional_Light,
}

Ambient_Light :: struct {
    intensity: f32,
}

Point_Light :: struct {
    intensity: f32,
    position: Vector3f32,
}

Directional_Light :: struct {
    intensity: f32,
    direction: Vector3f32,
}

Sphere :: struct {
    using position: Vector3f32,
    radius: f32,
    color: u32,
    specular: f32,
}

Scene :: struct {
    spheres: []Sphere,
    lights: []Light,
}

closest_intersection :: proc(scene: Scene, camera: Camera, ray: Vector3f32, t_min, t_max: f32) -> (closest_sphere: Maybe(Sphere), closest_t: f32) {
    closest_t = INF_F32
    for sphere in scene.spheres {
        t1, t2 := intersect_ray_sphere(camera, ray, sphere)
        if t1 >= t_min && t1 <= t_max && t1 < closest_t {
            closest_t = t1
            closest_sphere = sphere
        }
        if t2 >= t_min && t2 <= t_max && t2 < closest_t {
            closest_t = t2
            closest_sphere = sphere
        }
    }
    return
}

trace_ray :: proc(scene: Scene, camera: Camera, ray: Vector3f32, t_min: f32, t_max: f32) -> u32 {
    closest_sphere, closest_t := closest_intersection(scene, camera, ray, t_min, t_max)
    if closest_sphere == nil do return 0xFFFFFF
    c := closest_sphere.(Sphere)
    point := camera.position + closest_t * ray
    normal := linalg.normalize(point - c.position)
    r := (c.color & 0xFF0000) >> 16
    g := (c.color & 0x00FF00) >> 8
    b := (c.color & 0x0000FF)
    l := compute_lighting(scene, camera, point, normal, -ray, c.specular)

    // NOTE(pJotoro): Change this to true to make specular lighting at high levels cause colors higher than 255 to bleed into the other two. It's a total hack...
    when false {
        rl := f32(r) * l
        rl2 := rl
        gl := f32(g) * l
        gl2 := gl
        bl := f32(b) * l
        bl2 := bl

        if rl > 255 {
            diff := rl - 255
            rl2 -= diff
            gl2 += diff
            bl2 += diff
        }
        if gl > 255 {
            diff := gl - 255
            gl2 -= diff
            rl2 += diff
            bl2 += diff
        }
        if bl > 255 {
            diff := bl - 255
            bl2 -= diff
            gl2 += diff
            rl2 += diff
        }

        return (u32(rl2) << 16) | (u32(gl2) << 8) | (u32(bl2))
    } else {
        rl := f32(r) * l
        rl = clamp(rl, 0, 255)
        gl := f32(g) * l
        gl = clamp(gl, 0, 255)
        bl := f32(b) * l
        bl = clamp(bl, 0, 255)
        return (u32(rl) << 16) | (u32(gl) << 8) | (u32(bl))
    }
}

intersect_ray_sphere :: proc(camera: Camera, ray: Vector3f32, sphere: Sphere) -> (t1, t2: f32) {
    r := sphere.radius
    CO := camera.position - sphere.position

    a := linalg.dot(ray, ray)
    b := 2 * linalg.dot(CO, ray)
    c := linalg.dot(CO, CO) - r*r

    discriminant := b*b - 4*a*c
    if discriminant < 0 do return INF_F32, INF_F32

    t1 = (-b + linalg.sqrt(discriminant)) / (2*a)
    t2 = (-b - linalg.sqrt(discriminant)) / (2*a)
    return
}

compute_lighting :: proc(scene: Scene, camera: Camera, point, normal: Vector3f32, view: Vector3f32, specular: f32) -> (intensity: f32) {
    loop: for light in scene.lights {
        switch in light {
            case Ambient_Light:
                l := light.(Ambient_Light)
                intensity += l.intensity

            case Point_Light:
                l := light.(Point_Light)
                L := l.position - point
                t_max := f32(1)

                // Change to true to add shadows (they don't work right now, the screen just becomes blank).
                when false {
                    shadow_sphere, shadow_t := closest_intersection(scene, Camera{point}, L, 0.001, t_max)
                    if shadow_sphere != nil do continue loop
                }

                // diffuse
                n_dot_l := linalg.dot(normal, L)
                if n_dot_l > 0 {
                    intensity += l.intensity * n_dot_l/(linalg.length(normal) * linalg.length(L))
                }

                // specular
                if specular != -1 {
                    R := 2 * normal * linalg.dot(normal, L) - L
                    r_dot_v := linalg.dot(R, view)
                    if r_dot_v > 0 {
                        intensity += l.intensity * math.pow(r_dot_v/(linalg.length(R) * linalg.length(view)), specular)
                    }
                }

            case Directional_Light:
                l := light.(Directional_Light)
                L := l.direction
                t_max := INF_F32

                // Change to true to add shadows (they don't work right now, the screen just becomes blank).
                when false {
                    shadow_sphere, shadow_t := closest_intersection(scene, Camera{point}, L, 0.001, t_max)
                    if shadow_sphere != nil do continue loop
                }

                // diffuse
                n_dot_l := linalg.dot(normal, L)
                if n_dot_l > 0 {
                    intensity += l.intensity * n_dot_l/(linalg.length(normal) * linalg.length(L))
                }

                // specular
                if specular != -1 {
                    R := 2 * normal * linalg.dot(normal, L) - L
                    r_dot_v := linalg.dot(R, view)
                    if r_dot_v > 0 {
                        intensity += l.intensity * math.pow(r_dot_v/(linalg.length(R) * linalg.length(view)), specular)
                    }
                }
        }
    }
    return
}

draw_pixel :: proc(bitmap: []u32, color: u32, x, y: int) #no_bounds_check {
    if x < 0 do return
    if x >= app.width() do return
    if y < 0 do return
    if y >= app.height() do return
    bitmap[x + y*app.width()] = color
}

main :: proc() {
    app.init("Hello, world!", 720, 720)
    
    bitmap := make([]u32, app.width() * app.height())

    sphere1 := Sphere{position = {0, -1, 3}, radius = 1, color = 155 << 16, specular = 500}
    sphere2 := Sphere{position = {2, 0, 4}, radius = 1, color = 155, specular = 500}
    sphere3 := Sphere{position = {-2, 0, 4}, radius = 1, color = 155 << 8, specular = 10}
    sphere4 := Sphere{position = {0, -5001, 0}, radius = 5000, color = (155 << 16) | (155 << 8), specular = 1000}

    spheres := [?]Sphere{sphere1, sphere2, sphere3, sphere4}

    light1 := Ambient_Light{intensity = 0.2}
    light2 := Point_Light{intensity = 0.6, position = {2, 1, 0}}
    light3 := Directional_Light{intensity = 0.2, direction = {1, 4, 4}}

    lights := [?]Light{light1, light2, light3}

    scene := Scene{spheres = spheres[:], lights = lights[:]}
    camera := Camera{{0, 0, 0}}
    viewport := Viewport{1, 1, 1}
   
    for !app.should_close() {
        slice.fill(bitmap, 0)

        for x in 0..<app.width() {
            for y in 0..<app.height() {
                ray := screen_to_viewport(viewport, x - app.width()/2, y - app.height()/2)
                color := trace_ray(scene, camera, ray, 1, INF_F32)
                draw_pixel(bitmap, color, x, y)
            }
        }
        app.render(bitmap)
        
    }
}