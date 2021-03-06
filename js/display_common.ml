module ApiTypes = ApiTypes_j
module Html = Tyxml_js.Html5
module UIState = Ui_state

let toggle_element projection content =
  Html.div
    ~a:[Tyxml_js.R.Html.a_class
           (React.S.bind
              UIState.model_runtime_state
              (fun state -> React.S.const
                (match projection state with
                  [] -> ["hidden"]
                | _::_ -> ["show"])
              )
           )]
    content


let option_label label =
  if String.length label > 10 then
    (String.sub label 0 7)^"..."
  else
    label


let export_controls
    ~(export_select_id : string)
    ~(export_filename_id : string)
    ~(export_button_id : string)
    ~(export_data_label : string) =
  let export_formats : string list =
    [export_data_label]
  in
  let export_filename =
    Html.input
      ~a:[ Html.a_id export_filename_id ;
           Html.a_input_type `Text;
           Html.a_class ["form-control"];
           Html.a_placeholder "file name"]
      ()
  in
  let export_button =
    Html.button
      ~a:[ Html.a_id export_button_id
         ; Html.Unsafe.string_attrib "role" "button"
         ; Html.a_class ["btn";"btn-default";"pull-right"]
         ]
      [ Html.cdata "export" ]
  in
  let export_formats_select =
    List.map
      (fun format ->
        <:html<<option $list:Html.a_value format$>
           $str:format$
        </option> >>)
      export_formats
  in
  <:html<<div class="row">
  <div class="col-sm-12">
     <div class="form-inline">
        <div class="form-group">
           <select class="form-control"
                   $list:Html.a_id export_select_id$>
              <option value="png">png</option>
              <option value="svg">svg</option>
              $list:export_formats_select$
           </select>
        </div>
        <div class="form-group">
           <label class="checkbox-inline">
              $export_filename$
           </label>
        </div>
        <div class="form-group">
           <label class="checkbox-inline">
              $export_button$
           </label>
        </div>
     </div>
  </div>
</div> >>

let document = Dom_html.window##document

let default_svg_style_id = "plot-svg-style"

let save_plot_ui
    export_data
    title
    export_button_id
    export_filename_id
    export_format_id
    svg_div_id
    ?(svg_style_id = (Some default_svg_style_id))
    dat_file_extension
  =
  let export_button : Dom_html.buttonElement Js.t =
    Js.Unsafe.coerce
      ((Js.Opt.get
          (document##getElementById (Js.string export_button_id))
          (fun () -> assert false))
       : Dom_html.element Js.t) in
  let export_filename : Dom_html.inputElement Js.t =
    Js.Unsafe.coerce
      ((Js.Opt.get
          (document##getElementById (Js.string export_filename_id))
          (fun () -> assert false))
       : Dom_html.element Js.t) in
  let export_format : Dom_html.inputElement Js.t =
    Js.Unsafe.coerce
      ((Js.Opt.get
          (document##getElementById (Js.string export_format_id))
          (fun () -> assert false))
       : Dom_html.element Js.t) in
  let export_button_toggle () : unit =
    let filename : string =
      Js.to_string (export_filename##value)
    in
    let is_disabled : bool Js.t =
      Js.bool
        (String.length (String.trim filename) == 0)
    in
    let () =
      export_button##disabled <- is_disabled
    in
    ()
  in
  let () =
    export_button_toggle ()
  in
  let () =
    export_filename##oninput <-
      Dom_html.handler
      (fun _ ->
        let () = export_button_toggle () in
        Js._true)
  in
  let () =
    export_button##onclick <-
      Dom_html.handler
      (fun _ ->
        let suffix : string =
          Js.to_string (export_format##value)
        in
        let filename default : string =
          let root : string =
            Js.to_string (export_filename##value)
          in
          if String.contains root '.' then
            root
          else
            root^"."^default
      in
        let () = match suffix with
            "svg" -> Common.plotSVG svg_div_id
              title
              (filename "svg")
                                 svg_style_id
          | "png" ->
            Common.plotPNG
              svg_div_id
              title
              (filename "png")
              svg_style_id
          | "dat" -> export_data (filename dat_file_extension)
        | f -> Common.error ("Unknown format"^f)
        in
        Js._true)
  in
  ()
let badge counter
    =
  [ Tyxml_js.R.Html.span
      (let badge_list, badge_handle =
         ReactiveData.RList.create [] in
       let _ = React.S.map
             (fun state ->
               let count = counter state in
               if count > 0  then
                 ReactiveData.RList.set
                   badge_handle
                   [ Html.pcdata " ";
                     Html.span ~a:[ Html.a_class ["badge"]]
                       [ Html.pcdata (string_of_int count) ]
                   ]
               else
                 ReactiveData.RList.set badge_handle []
             )
             UIState.model_runtime_state in
       badge_list
      )
  ]
