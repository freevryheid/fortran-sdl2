! music.f90
!
! Plays an OGG file using SDL2_mixer and outputs some text
! with SDL2_ttf (software renderer).
!
! Author:   Philipp Engel
! Licence:  ISC
program main
    use, intrinsic :: iso_c_binding, only: c_null_char, c_ptr
    use :: sdl2
    use :: sdl2_consts
    use :: sdl2_types
    use :: sdl2_mixer
    use :: sdl2_ttf
    implicit none

    integer,          parameter :: width    = 320
    integer,          parameter :: height   = 240
    character(len=*), parameter :: ogg_path = 'examples/music/music.ogg'
    character(len=*), parameter :: ttf_path = 'examples/music/font.ttf'
    character(len=*), parameter :: message  = 'Playing ' // ogg_path // ' ...'

    logical           :: done = .false.
    type(c_ptr)       :: window
    type(sdl_surface) :: screen
    type(sdl_surface) :: text
    type(sdl_rect)    :: rect
    type(sdl_event)   :: event
    type(sdl_color)   :: color
    type(c_ptr)       :: font
    type(c_ptr)       :: music
    integer           :: rc

    ! Initialise SDL.
    rc = sdl_init(ior(sdl_init_video, sdl_init_audio))

    if (rc < 0) then
        print *, 'SDL Error: ', sdl_get_error()
        call exit(1)
    end if

    ! Initialise SDL_ttf.
    rc = ttf_init()

    if (rc < 0) then
        print *, 'TTF Error: ', sdl_get_error()
        call exit(1)
    end if

    ! Open font and draw to surface.
    color%r = 255; color%g = 165; color%b = 0; color%a = 255
    font    = ttf_open_font(ttf_path // c_null_char, 12)
    text    = ttf_render_text_solid(font, message // c_null_char, color)

    rect%x = 0
    rect%y = 0
    rect%w = text%w
    rect%h = text%h

    ! Initialise SDL_mixer.
    rc = mix_open_audio(mix_default_frequency, &
                        audio_s16lsb, &
                        mix_default_channels, &
                        4096)

    if (rc < 0) then
        print *, 'MIX Error: ', sdl_get_error()
        call exit(1)
    end if

    ! Play music.
    music = mix_load_mus(ogg_path // c_null_char)
    rc    = mix_play_music(music, -1)

    if (rc < 0) then
        print *, 'MIX Error: ', sdl_get_error()
        call exit(1)
    end if

    ! Create the SDL window.
    window = sdl_create_window('SDL2 Fortran' // c_null_char, &
                               sdl_windowpos_undefined, &
                               sdl_windowpos_undefined, &
                               width, &
                               height, &
                               sdl_window_shown)

    if (.not. c_associated(window)) then
        print *, 'SDL Error: ', sdl_get_error()
        call exit(1)
    end if

    ! Get the window surface.
    screen = sdl_get_window_surface(window)
    rc     = sdl_update_window_surface(window)

    ! Event loop.
    do while (.not. done)
        rc = sdl_poll_event(event)

        if (rc > 0) then
            select case (event%type)
                case (sdl_quit_type)
                    done = .true.
            end select

            ! Copy text surface to screen.
            rc = sdl_blit_surface(text, rect, screen, rect)
            rc = sdl_update_window_surface(window)
        else
            call sdl_delay(50)
        end if
    end do

    ! Quit gracefully.
    call mix_free_music(music)
    call mix_close_audio()

    call ttf_close_font(font)
    call ttf_quit()

    call sdl_free_surface(text)
    call sdl_destroy_window(window)
    call sdl_quit()
end program main
