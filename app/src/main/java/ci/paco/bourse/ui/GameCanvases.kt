package ci.paco.bourse.ui

import android.graphics.Paint
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.*
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import ci.paco.bourse.*
import ci.paco.bourse.domain.*
import kotlin.math.*

@Composable
fun CityCanvas(ui: UiState, vm: PacoViewModel, art: Map<String, ImageBitmap>) {
    var viewport by remember { mutableStateOf(IntSize.Zero) }
    var zoom by remember { mutableFloatStateOf(1f) }
    var pan by remember { mutableStateOf(Offset.Zero) }
    val player by rememberUpdatedState(ui.player)
    val life = rememberInfiniteTransition(label = "Vie de la ville")
    val movement by
        life.animateFloat(
            initialValue = 0f,
            targetValue = 1f,
            animationSpec = infiniteRepeatable(tween(10000, easing = LinearEasing)),
            label = "Passants",
        )
    val time = if (vm.reducedMotion) .3f else movement
    val textPaint = remember {
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = android.graphics.Color.rgb(36, 69, 58)
            textSize = 23f
            typeface =
                android.graphics.Typeface.create(
                    "sans-serif-rounded",
                    android.graphics.Typeface.BOLD,
                )
            textAlign = Paint.Align.CENTER
        }
    }
    fun center(x: Float = 740f, y: Float = 490f) {
        zoom = (viewport.width / 820f).coerceAtLeast(.35f)
        pan = Offset(viewport.width / 2 - x * zoom, viewport.height / 2 - y * zoom)
    }
    LaunchedEffect(viewport, ui.focusLand) {
        if (viewport.width > 0) {
            val land = lands.firstOrNull { it.id == ui.focusLand }
            center(land?.x ?: 740f, land?.y ?: 490f)
        }
    }
    fun zoomBy(factor: Float) {
        val next = (zoom * factor).coerceIn(viewport.width / 2400f, viewport.width / 350f)
        val focus = Offset(viewport.width / 2f, viewport.height / 2f)
        pan = focus - (focus - pan) * (next / zoom)
        zoom = next
    }
    Box(Modifier.fillMaxSize()) {
        if (art["buildings/city-garden.png"] == null)
            CircularProgressIndicator(
                Modifier.align(Alignment.Center).semantics {
                    contentDescription = "Chargement de la ville"
                }
            )
        Canvas(
            Modifier.fillMaxSize()
                .onSizeChanged { viewport = it }
                .semantics {
                    contentDescription =
                        "Ville isométrique. Déplace et zoome la carte. Les propriétés sont aussi accessibles dans la liste."
                }
                .pointerInput(Unit) {
                    detectTransformGestures { centroid, drag, scale, _ ->
                        val next =
                            (zoom * scale).coerceIn(viewport.width / 2400f, viewport.width / 350f)
                        pan = centroid - (centroid - pan) * (next / zoom) + drag
                        zoom = next
                    }
                }
                .pointerInput(Unit) {
                    detectTapGestures { point ->
                        val world = (point - pan) / zoom
                        val land = lands.firstOrNull {
                            abs(world.x - it.x) < 170 && abs(world.y - it.y) < 145
                        }
                        if (land != null) vm.navigate(Screen.GROWTH)
                        else if (world.x in 635f..855f && world.y in 130f..360f)
                            vm.navigate(Screen.COMPANY)
                        else
                            listOf(
                                    Triple("cacao", 480f, 465f),
                                    Triple("telecom", 1000f, 465f),
                                    Triple("banque", 755f, 680f),
                                )
                                .firstOrNull {
                                    abs(world.x - it.second) < 120 &&
                                        world.y in (it.third - 170)..(it.third + 100)
                                }
                                ?.let { vm.navigate(Screen.COMPANY, it.first) }
                    }
                }
        ) {
            withTransform({
                translate(pan.x, pan.y)
                scale(zoom, zoom, Offset.Zero)
            }) {
                fun sprite(name: String, x: Float, y: Float, w: Int, h: Int) {
                    art[name]?.let {
                        drawImage(
                            it,
                            dstOffset = IntOffset((x - w / 2).roundToInt(), (y - h).roundToInt()),
                            dstSize = IntSize(w, h),
                        )
                    }
                }
                fun label(text: String, x: Float, y: Float) {
                    val width = maxOf(190f, text.length * 12f)
                    drawRoundRect(
                        Color(0xFFFFF8E7),
                        Offset(x - width / 2, y),
                        Size(width, 48f),
                        CornerRadius(13f),
                    )
                    drawIntoCanvas { it.nativeCanvas.drawText(text, x, y + 32, textPaint) }
                }
                art["buildings/city-garden.png"]?.let {
                    drawImage(it, dstSize = IntSize(1400, 1000))
                }
                var previous = Offset(1250f, 500f)
                lands.forEach { land ->
                    val point = Offset(land.x, land.y)
                    if (land.id in player.plots) {
                        drawLine(Color(0xFFFFEBC3), previous, point, 32f)
                        drawLine(Color(0xFFD4AF7B), previous, point, 20f)
                    }
                    previous = point
                    val shape =
                        Path().apply {
                            moveTo(land.x, land.y - 90)
                            lineTo(land.x + 165, land.y)
                            lineTo(land.x, land.y + 90)
                            lineTo(land.x - 165, land.y)
                            close()
                        }
                    drawPath(
                        shape,
                        if (land.id in player.plots) Color(0xFF9DD05D)
                        else Color(0xFF83C7A0).copy(alpha = .65f),
                    )
                    drawPath(shape, Color(0xFFFFEBC3), style = Stroke(5f))
                    val building = buildings.firstOrNull { it.id == player.constructions[land.id] }
                    if (building != null)
                        sprite("buildings/${building.asset}.webp", land.x, land.y + 40, 190, 170)
                    else {
                        drawCircle(Color(0xFFFFE5A0), 35f, point)
                        drawLine(
                            Color(0xFF487661),
                            point - Offset(18f, 0f),
                            point + Offset(18f, 0f),
                            6f,
                        )
                        drawLine(
                            Color(0xFF487661),
                            point - Offset(0f, 18f),
                            point + Offset(0f, 18f),
                            6f,
                        )
                    }
                    label(land.name, land.x, land.y + 94)
                }
                sprite("buildings/services-1.webp", 745f, 290f, 190, 160)
                label("Guichet", 745f, 305f)
                listOf(
                        Triple("cacao", 480f, 465f),
                        Triple("telecom", 1000f, 465f),
                        Triple("banque", 755f, 680f),
                    )
                    .forEach { (id, x, y) ->
                        val c = companies.first { it.id == id }
                        val held = player.holdings.getValue(id)
                        if (held > 0) sprite("buildings/${c.asset}.webp", x, y, 200, 165)
                        else {
                            drawCircle(Color(0xFFFFE5A0), 36f, Offset(x, y - 35))
                            drawLine(
                                Color(0xFF487661),
                                Offset(x - 18, y - 35),
                                Offset(x + 18, y - 35),
                                6f,
                            )
                            drawLine(Color(0xFF487661), Offset(x, y - 53), Offset(x, y - 17), 6f)
                        }
                        label(
                            "${when(id){"cacao"->"Agro"
"telecom"->"Télécoms"
else->"Banque"}} · $held part(s)",
                            x,
                            y + 15,
                        )
                    }
                sprite(
                    "buildings/passant-vert.webp",
                    390f + 650f * time,
                    320f + 360f * time,
                    28,
                    40,
                )
                sprite(
                    "buildings/passant-rouge.webp",
                    1040f - 650f * time,
                    680f - 360f * time,
                    28,
                    40,
                )
            }
        }
        Column(
            Modifier.align(Alignment.BottomEnd).padding(end = 12.dp, bottom = 180.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            FilledTonalButton(
                onClick = { zoomBy(1.25f) },
                modifier = Modifier.semantics { contentDescription = "Agrandir la vue" },
            ) {
                Text("+")
            }
            FilledTonalButton(
                onClick = { zoomBy(.8f) },
                modifier = Modifier.semantics { contentDescription = "Réduire la vue" },
            ) {
                Text("−")
            }
            FilledTonalButton(
                onClick = { center() },
                modifier = Modifier.semantics { contentDescription = "Recentrer la ville" },
            ) {
                Text("Centrer", fontSize = 11.sp)
            }
        }
    }
}

@Composable
fun PuzzleScreen(p: PuzzleUi, vm: PacoViewModel, art: Map<String, ImageBitmap>) {
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(8.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Art("paco/confiance.webp", art, 48.dp)
            Text(
                "Niveau ${p.level+1} · ${lessons[p.level].topic}",
                style = MaterialTheme.typography.titleLarge,
            )
        }
        Panel(color = Color(0xFFFFF1CF)) {
            Text(
                "${p.moves} coups · ${p.score} / ${p.target} points",
                style = MaterialTheme.typography.titleMedium,
            )
            LinearProgressIndicator(
                progress = { (p.score.toFloat() / p.target).coerceIn(0f, 1f) },
                modifier = Modifier.fillMaxWidth(),
            )
        }
        Panel(color = if (p.remaining <= 10) Color(0xFFFFD8D2) else Color(0xFFE5F5FF)) {
            Text(
                "Temps restant : ${p.remaining/60}:${(p.remaining%60).toString().padStart(2,'0')}",
                fontWeight = FontWeight.Black,
                modifier =
                    Modifier.semantics {
                        if (p.remaining <= 10) liveRegion = LiveRegionMode.Polite
                    },
            )
        }
        BoxWithConstraints(Modifier.fillMaxWidth()) {
            val side = maxOf(maxWidth, 344.dp)
            Box(Modifier.horizontalScroll(rememberScrollState())) {
                PuzzleBoard(p, vm, art, Modifier.size(side))
            }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Button(
                onClick = vm::hint,
                enabled = p.started && !p.busy && p.outcome == null,
                modifier = Modifier.weight(1f),
            ) {
                Text("Un indice")
            }
            var showHelp by remember { mutableStateOf(false) }
            OutlinedButton(onClick = { showHelp = true }) { Text("Consigne") }
            if (showHelp && p.outcome == null) Instructions(p, vm, art, false) { showHelp = false }
        }
    }
    if (!p.started) Instructions(p, vm, art, true) {}
    if (p.outcome != null) ResultDialog(p, vm, art)
}

@Composable
private fun PuzzleBoard(
    p: PuzzleUi,
    vm: PacoViewModel,
    art: Map<String, ImageBitmap>,
    modifier: Modifier,
) {
    val progress = remember { Animatable(1f) }
    LaunchedEffect(p.sequence) {
        if (p.frame != null) {
            progress.snapTo(0f)
            progress.animateTo(
                1f,
                tween(
                    if (vm.reducedMotion) 0
                    else
                        when (p.frame.phase) {
                            Phase.SWAP,
                            Phase.REVERT -> 150
                            Phase.CLEAR -> 160
                            Phase.FALL -> 220
                            Phase.SHUFFLE -> 240
                        },
                    easing = LinearOutSlowInEasing,
                ),
            )
        }
    }
    var canvasSize by remember { mutableStateOf(IntSize.Zero) }
    val enabled = p.started && !p.busy && p.outcome == null
    val tileNames = listOf("cacao", "telephone", "billet", "bidon", "ampoule", "engrenage")
    Box(
        modifier
            .background(Color(0xFF493269), RoundedCornerShape(18.dp))
            .border(3.dp, Color(0xFFFFD975), RoundedCornerShape(18.dp))
            .padding(5.dp)
    ) {
        Canvas(
            Modifier.fillMaxSize()
                .onSizeChanged { canvasSize = it }
                .pointerInput(enabled) {
                    detectTapGestures {
                        if (enabled) {
                            val u = size.width / 7f
                            vm.select((it.y / u).toInt() * 7 + (it.x / u).toInt())
                        }
                    }
                }
                .pointerInput(enabled) {
                    var from = Offset.Zero
                    var drag = Offset.Zero
                    detectDragGestures(
                        onDragStart = {
                            from = it
                            drag = Offset.Zero
                        },
                        onDrag = { change, delta ->
                            change.consume()
                            drag += delta
                        },
                        onDragEnd = {
                            if (enabled) {
                                val u = size.width / 7f
                                if (drag.getDistance() >= u * .2f) {
                                    val a = (from.y / u).toInt() * 7 + (from.x / u).toInt()
                                    val b =
                                        a +
                                            if (abs(drag.x) > abs(drag.y)) {
                                                if (drag.x > 0) 1 else -1
                                            } else {
                                                if (drag.y > 0) 7 else -7
                                            }
                                    vm.swap(a, b)
                                }
                            }
                        },
                    )
                }
        ) {
            val u = size.width / 7
            val t = progress.value
            val frame = p.frame
            fun position(i: Int) = Offset(Math.floorMod(i, 7) * u, Math.floorDiv(i, 7) * u)
            fun tile(type: Int, point: Offset, scale: Float = 1f, alpha: Float = 1f) {
                if (type !in 0..5) return
                val bitmap = art["tiles/${tileNames[type]}.webp"] ?: return
                val edge = (u * .93f * scale).roundToInt().coerceAtLeast(1)
                val origin = point + Offset((u - edge) / 2, (u - edge) / 2)
                drawImage(
                    bitmap,
                    dstOffset = IntOffset(origin.x.roundToInt(), origin.y.roundToInt()),
                    dstSize = IntSize(edge, edge),
                    alpha = alpha.coerceIn(0f, 1f),
                )
            }
            for (i in 0..48) drawRoundRect(
                Color(0xFF624C86),
                position(i) + Offset(2f, 2f),
                Size(u - 4, u - 4),
                CornerRadius(u * .18f),
            )
            clipRect {
                when (frame?.phase) {
                    Phase.FALL ->
                        frame.motions.forEach { m ->
                            tile(
                                m.type,
                                androidx.compose.ui.geometry.lerp(
                                    position(m.from),
                                    position(m.to),
                                    t,
                                ),
                            )
                        }
                    Phase.SWAP,
                    Phase.REVERT -> {
                        val moving = frame.motions.map { it.from }.toSet()
                        for (i in 0..48) if (i !in moving) tile(frame.before[i], position(i))
                        frame.motions.forEach { m ->
                            tile(
                                m.type,
                                androidx.compose.ui.geometry.lerp(
                                    position(m.from),
                                    position(m.to),
                                    t,
                                ),
                            )
                        }
                    }
                    Phase.CLEAR ->
                        for (i in 0..48) tile(
                            frame.before[i],
                            position(i),
                            if (i in frame.cleared) 1f - .8f * t else 1f,
                            if (i in frame.cleared) 1f - t else 1f,
                        )
                    Phase.SHUFFLE -> {
                        val source = if (t < .5f) frame.before else frame.after
                        for (i in 0..48) tile(source[i], position(i), alpha = abs(t * 2 - 1))
                    }
                    else -> for (i in 0..48) tile(p.board[i], position(i))
                }
                if (frame?.phase == Phase.CLEAR && !vm.reducedMotion)
                    frame.cleared.forEach { i ->
                        for (n in 0..5) {
                            val angle = n * PI / 3
                            drawCircle(
                                Color(0xFFFFD36F).copy(alpha = 1 - t),
                                u * .05f * (1 - t),
                                position(i) +
                                    Offset(u / 2, u / 2) +
                                    Offset(cos(angle).toFloat(), sin(angle).toFloat()) *
                                        (u * .6f * t),
                            )
                        }
                    }
            }
            for (i in 0..48) if (i == p.selected || i in p.hint)
                drawRoundRect(
                    Color(0xFFFFE9A0),
                    position(i) + Offset(2f, 2f),
                    Size(u - 4, u - 4),
                    CornerRadius(u * .18f),
                    style = Stroke(4f),
                )
        }
        Column(Modifier.fillMaxSize()) {
            for (y in 0..6) Row(Modifier.weight(1f)) {
                for (x in 0..6) {
                    val index = y * 7 + x
                    val type = p.board[index].takeIf { it >= 0 } ?: p.frame?.after?.get(index) ?: 0
                    Box(
                        Modifier.weight(1f).fillMaxHeight().semantics {
                            contentDescription =
                                "Ligne ${y+1}, colonne ${x+1}, ${tileNames[type.coerceIn(0,5)]}"
                            role = Role.Button
                            selected = index == p.selected
                            if (enabled)
                                onClick {
                                    vm.select(index)
                                    true
                                }
                            else disabled()
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun Instructions(
    p: PuzzleUi,
    vm: PacoViewModel,
    art: Map<String, ImageBitmap>,
    initial: Boolean,
    onClose: () -> Unit,
) {
    val artReady =
        listOf("cacao", "telephone", "billet", "bidon", "ampoule", "engrenage").all {
            "tiles/$it.webp" in art
        }
    AlertDialog(
        onDismissRequest = { if (!initial) onClose() },
        properties = DialogProperties(dismissOnBackPress = !initial, dismissOnClickOutside = false),
        title = { Text("Mission ${p.level+1} · ${lessons[p.level].topic}") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Art("paco/expliquer.webp", art, 80.dp)
                if (!artReady) {
                    LinearProgressIndicator(Modifier.fillMaxWidth())
                    Text("Chargement du plateau…")
                }
                Text(
                    "Objectif : ${p.target} points en ${secondsFor(p.level)} secondes et ${24-p.level} coups maximum."
                )
                Text(
                    "Glisse une pièce vers sa voisine pour aligner au moins 3 symboles. Deux taps sur des cases voisines fonctionnent aussi. Un échange sans alignement revient en place sans utiliser de coup."
                )
                Text(
                    if (initial)
                        "Le chrono démarre à « C’est parti ». Il continue pendant l’aide et les passages en arrière-plan."
                    else "Le chrono continue pendant la lecture de cette aide."
                )
            }
        },
        confirmButton = {
            Button(
                enabled = artReady,
                onClick = {
                    if (initial) vm.startRound()
                    onClose()
                },
            ) {
                Text(if (initial) "C’est parti" else "Reprendre")
            }
        },
        dismissButton = {
            if (initial)
                TextButton(onClick = { vm.navigate(Screen.HOME) }) { Text("Menu principal") }
        },
    )
}

@Composable
private fun ClayTitle(won: Boolean, reduced: Boolean) {
    var shown by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { shown = true }
    val scale by
        animateFloatAsState(
            if (shown) 1f else .72f,
            if (reduced) tween(0) else spring(dampingRatio = .42f, stiffness = 180f),
            label = "Rebond du résultat",
        )
    val text = if (won) "GAGNE" else "PAS DE\nCHANCE"
    Box(
        Modifier.scale(scale).semantics(mergeDescendants = true) {
            contentDescription = if (won) "GAGNE" else "PAS DE CHANCE"
        },
        contentAlignment = Alignment.Center,
    ) {
        for (i in 7 downTo 1) Text(
            text,
            Modifier.offset(y = i.dp).clearAndSetSemantics {},
            color = if (won) Color(0xFF9D5B1E) else Color(0xFF9F4F5C),
            fontSize = if (won) 48.sp else 36.sp,
            fontWeight = FontWeight.Black,
            fontFamily = PacoFont,
            lineHeight = 39.sp,
        )
        Text(
            text,
            Modifier.clearAndSetSemantics {},
            color = if (won) Color(0xFFFFE47E) else Color(0xFFFFC4B7),
            fontSize = if (won) 48.sp else 36.sp,
            fontWeight = FontWeight.Black,
            fontFamily = PacoFont,
            lineHeight = 39.sp,
        )
    }
}

@Composable
private fun ResultDialog(p: PuzzleUi, vm: PacoViewModel, art: Map<String, ImageBitmap>) {
    val won = p.outcome == "GAGNE"
    Dialog(
        onDismissRequest = {},
        properties = DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false),
    ) {
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(vertical = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            ClayTitle(won, vm.reducedMotion)
            Panel(color = Color(0xFFFFF1D4)) {
                Art(if (won) "paco/reussir.webp" else "paco/reconfort.webp", art, 95.dp)
                Text(p.reason, style = MaterialTheme.typography.titleLarge)
                Text(
                    if (won)
                        if (p.saving) "Enregistrement de ta réussite…"
                        else if (p.saved)
                            "Ta réussite est enregistrée. La récompense est versée une seule fois. Retrouve Paco pour valider la notion."
                        else "L’enregistrement a échoué. Réessaie avant de continuer."
                    else
                        "Tu conserves ton épargne et tes acquis. Prêt pour une nouvelle tentative ?"
                )
                if (won)
                    Button(
                        onClick = { if (p.saved) vm.resultLesson() else vm.retrySave() },
                        enabled = !p.saving,
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text(
                            if (p.saving) "Enregistrement…"
                            else if (p.saved) "Comprendre avec Paco"
                            else "Réessayer l’enregistrement"
                        )
                    }
                else
                    Button(onClick = vm::retryRound, modifier = Modifier.fillMaxWidth()) {
                        Text("Rejouer")
                    }
                OutlinedButton(
                    onClick = { vm.navigate(Screen.HOME) },
                    enabled = !p.saving,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Menu principal")
                }
            }
        }
    }
}
