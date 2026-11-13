$files = Get-ChildItem -Path "lib", "test" -Recurse -File -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw

    # Remove GoF imports
    $content = $content -replace "(?m)^import 'package:control_asistencia/controlador/observer/.*`r?`n", ""
    $content = $content -replace "(?m)^import 'package:control_asistencia/controlador/memento/.*`r?`n", ""
    $content = $content -replace "(?m)^import 'package:control_asistencia/controlador/strategy/.*`r?`n", ""

    # Replace Import Paths
    $content = $content.Replace('package:control_asistencia/model/db/database_helper.dart', 'package:control_asistencia/modelo/dato/conexion.dart')
    $content = $content.Replace('package:control_asistencia/model/db/', 'package:control_asistencia/modelo/dato/')
    $content = $content.Replace('package:control_asistencia/model/', 'package:control_asistencia/modelo/negocio/n_')
    
    $content = $content.Replace('package:control_asistencia/controlador/asistencia_controller.dart', 'package:control_asistencia/controlador/c_asistencia.dart')
    $content = $content.Replace('package:control_asistencia/controlador/estudiante_controller.dart', 'package:control_asistencia/controlador/c_estudiante.dart')
    $content = $content.Replace('package:control_asistencia/controlador/excel_controller.dart', 'package:control_asistencia/controlador/c_excel.dart')

    $content = $content.Replace('package:control_asistencia/view/screens/selector_rol_screen.dart', 'package:control_asistencia/vista/v_selector_rol.dart')
    $content = $content.Replace('package:control_asistencia/view/screens/estudiante/registro_estudiante_screen.dart', 'package:control_asistencia/vista/estudiante/v_registro_estudiante.dart')
    $content = $content.Replace('package:control_asistencia/view/screens/estudiante/estudiante_qr_screen.dart', 'package:control_asistencia/vista/estudiante/v_estudiante_qr.dart')
    $content = $content.Replace('package:control_asistencia/view/screens/docente/docente_home_screen.dart', 'package:control_asistencia/vista/docente/v_docente_home.dart')
    $content = $content.Replace('package:control_asistencia/view/screens/docente/materia_detalle_screen.dart', 'package:control_asistencia/vista/docente/v_materia_detalle.dart')
    $content = $content.Replace('package:control_asistencia/view/screens/docente/examen_asistencia_screen.dart', 'package:control_asistencia/vista/docente/v_examen_asistencia.dart')
    $content = $content.Replace('package:control_asistencia/view/screens/docente/escanear_qr_screen.dart', 'package:control_asistencia/vista/docente/v_escanear_qr.dart')

    # Replace Class Names (Controllers first)
    $content = $content -replace '\bAsistenciaController\b', 'CAsistencia'
    $content = $content -replace '\bEstudianteController\b', 'CEstudiante'
    $content = $content -replace '\bExcelController\b', 'CExcel'

    # Views
    $content = $content -replace '\bSelectorRolScreen\b', 'VSelectorRol'
    $content = $content -replace '\bRegistroEstudianteScreen\b', 'VRegistroEstudiante'
    $content = $content -replace '\bEstudianteQrScreen\b', 'VEstudianteQr'
    $content = $content -replace '\bDocenteHomeScreen\b', 'VDocenteHome'
    $content = $content -replace '\bMateriaDetalleScreen\b', 'VMateriaDetalle'
    $content = $content -replace '\bExamenAsistenciaScreen\b', 'VExamenAsistencia'
    $content = $content -replace '\bEscanearQrScreen\b', 'VEscanearQr'

    # Models / Entities
    $content = $content -replace '\bDatabaseHelper\b', 'Conexion'
    $content = $content -replace '\bAsistencia\b', 'NAsistencia'
    $content = $content -replace '\bEstudiante\b', 'NEstudiante'
    $content = $content -replace '\bExamen\b', 'NExamen'
    $content = $content -replace '\bMateria\b', 'NMateria'

    Set-Content -Path $file.FullName -Value $content -NoNewline
}
