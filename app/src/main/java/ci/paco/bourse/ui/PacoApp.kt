@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)

package ci.paco.bourse.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.*
import androidx.compose.ui.unit.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import ci.paco.bourse.*
import ci.paco.bourse.R
import ci.paco.bourse.data.*
import ci.paco.bourse.domain.*

private val Cream = Color(0xFFFFF6DF)
private val Ink = Color(0xFF263F50)
private val Purple = Color(0xFF7350AF)
private val Gold = Color(0xFFFFD46B)
val PacoFont =
    FontFamily(
        Font(R.font.paco_regular, FontWeight.Normal),
        Font(R.font.paco_semibold, FontWeight.SemiBold),
        Font(R.font.paco_bold, FontWeight.Bold),
        Font(R.font.paco_black, FontWeight.Black),
    )

fun money(n: Number) = "%,d".format(java.util.Locale.FRANCE, n.toLong())

@Composable
fun PacoApp(vm: PacoViewModel) {
    val ui by vm.ui.collectAsStateWithLifecycle()
    val art = rememberArt()
    val colors =
        lightColorScheme(
            primary = Color(0xFF225E46),
            secondary = Purple,
            secondaryContainer = Gold,
            surface = Cream,
            onSurface = Ink,
        )
    val typography =
        Typography(
            bodyLarge = TextStyle(fontFamily = PacoFont, fontSize = 16.sp, lineHeight = 23.sp),
            bodyMedium = TextStyle(fontFamily = PacoFont, fontSize = 14.sp, lineHeight = 21.sp),
            titleLarge =
                TextStyle(
                    fontFamily = PacoFont,
                    fontSize = 22.sp,
                    fontWeight = FontWeight.ExtraBold,
                ),
            titleMedium =
                TextStyle(fontFamily = PacoFont, fontSize = 18.sp, fontWeight = FontWeight.Bold),
            headlineMedium =
                TextStyle(fontFamily = PacoFont, fontSize = 29.sp, fontWeight = FontWeight.Black),
            labelLarge =
                TextStyle(fontFamily = PacoFont, fontSize = 15.sp, fontWeight = FontWeight.Bold),
        )
    MaterialTheme(colorScheme = colors, typography = typography) {
        val snack = remember { SnackbarHostState() }
        LaunchedEffect(ui.message) {
            ui.message?.let {
                snack.showSnackbar(it)
                vm.clearMessage()
            }
        }
        BackHandler(
            enabled =
                ui.screen != Screen.HOME &&
                    ui.puzzle?.outcome == null &&
                    ui.puzzle?.started != false
        ) {
            vm.navigate(Screen.HOME)
        }
        Scaffold(
            containerColor = if (ui.screen == Screen.PUZZLE) Color(0xFFECE4FA) else Cream,
            snackbarHost = {
                SnackbarHost(snack, Modifier.navigationBarsPadding().padding(bottom = 120.dp))
            },
            topBar = {
                if (ui.screen != Screen.HOME)
                    TopAppBar(
                        title = { Text(title(ui.screen)) },
                        navigationIcon = {
                            TextButton(onClick = { vm.navigate(Screen.HOME) }, enabled = !ui.busy) {
                                Text("Accueil")
                            }
                        },
                    )
            },
        ) { padding ->
            if (ui.loading)
                Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            else if (ui.error != null)
                Column(
                    Modifier.padding(padding).padding(24.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                ) {
                    Text(ui.error!!)
                    Button(onClick = vm::load) { Text("Réessayer") }
                }
            else
                Box(Modifier.fillMaxSize().padding(padding)) {
                    when (ui.screen) {
                        Screen.HOME -> Home(ui, vm, art)
                        Screen.LEVELS -> Levels(ui, vm)
                        Screen.PUZZLE -> ui.puzzle?.let { PuzzleScreen(it, vm, art) }
                        Screen.PROPERTIES -> Properties(ui, vm, art, false)
                        Screen.CARDS -> Properties(ui, vm, art, true)
                        Screen.COMPANY -> CompanyScreen(ui, vm, art)
                        Screen.GROWTH -> Growth(ui, vm, art)
                        Screen.JOURNEY -> Journey(ui, vm)
                        Screen.SETTINGS -> SettingsScreen(ui, vm)
                        Screen.HISTORY ->
                            LazyColumn(
                                contentPadding = PaddingValues(20.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp),
                            ) {
                                items(ui.player.history.size) {
                                    Text(ui.player.history.reversed()[it])
                                }
                                if (ui.player.history.isEmpty())
                                    item { Text("Tes décisions apparaîtront ici.") }
                            }
                    }
                }
        }
        ui.lesson?.let { LessonDialog(it, ui, vm, art) }
        ui.importDraft?.let { p ->
            AlertDialog(
                onDismissRequest = vm::cancelImport,
                title = { Text("Importer cette sauvegarde ?") },
                text = {
                    Text(
                        "${money(p.cash)} FCFA-jeu · ${p.completed.size} puzzles · ${p.plots.size} terrains. Cette opération remplace la sauvegarde Kotlin actuelle, sans additionner les récompenses."
                    )
                },
                confirmButton = {
                    Button(onClick = vm::confirmImport, enabled = !ui.busy) { Text("Remplacer") }
                },
                dismissButton = { TextButton(onClick = vm::cancelImport) { Text("Annuler") } },
            )
        }
    }
}

private fun title(screen: Screen) =
    when (screen) {
        Screen.LEVELS -> "Le chemin de Paco"
        Screen.PUZZLE -> "Puzzle"
        Screen.PROPERTIES -> "Mes propriétés"
        Screen.CARDS -> "Mes cartes"
        Screen.COMPANY -> "Le guichet"
        Screen.GROWTH -> "Agrandir ma ville"
        Screen.JOURNEY -> "Voyage de Paco"
        Screen.SETTINGS -> "Réglages"
        Screen.HISTORY -> "Mon carnet"
        else -> "Ma ville"
    }

@Composable
fun Art(
    name: String,
    art: Map<String, ImageBitmap>,
    size: Dp = 80.dp,
    description: String? = null,
) {
    art[name]?.let { Image(it, description, Modifier.size(size)) }
}

@Composable
fun Panel(
    modifier: Modifier = Modifier,
    color: Color = Cream,
    content: @Composable ColumnScope.() -> Unit,
) {
    Surface(
        modifier,
        shape = RoundedCornerShape(22.dp),
        color = color,
        shadowElevation = 5.dp,
        border = BorderStroke(2.dp, Color.White),
    ) {
        Column(
            Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            content = content,
        )
    }
}

@Composable
private fun Home(ui: UiState, vm: PacoViewModel, art: Map<String, ImageBitmap>) {
    Box(Modifier.fillMaxSize().background(Color(0xFF12B7BD))) {
        CityCanvas(ui, vm, art)
        Column(
            Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Panel(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Art("paco/accueil.webp", art, 42.dp)
                        Column {
                            Text("Ma ville", style = MaterialTheme.typography.titleMedium)
                            Text(
                                "${ui.player.answered.size}/6 notions · Kotlin",
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
                    }
                }
                FilledTonalButton(
                    onClick = { vm.navigate(Screen.SETTINGS) },
                    contentPadding = PaddingValues(12.dp),
                    modifier = Modifier.heightIn(min = 48.dp),
                ) {
                    Text("Menu")
                }
            }
            Surface(shape = RoundedCornerShape(16.dp), color = Gold, shadowElevation = 3.dp) {
                Text(
                    "${money(ui.player.cash)} FCFA-jeu",
                    Modifier.padding(12.dp),
                    fontWeight = FontWeight.Black,
                )
            }
        }
        Column(
            Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = { vm.navigate(Screen.GROWTH) },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Gold, contentColor = Ink),
                ) {
                    Text("Agrandir")
                }
                Button(
                    onClick = { vm.navigate(Screen.JOURNEY) },
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(containerColor = Gold, contentColor = Ink),
                ) {
                    Text("Voyager")
                }
            }
            Surface(color = Cream, shape = RoundedCornerShape(20.dp), shadowElevation = 5.dp) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    TextButton(
                        onClick = { vm.navigate(Screen.PROPERTIES) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Propriétés", fontSize = 12.sp)
                    }
                    TextButton(
                        onClick = { vm.navigate(Screen.CARDS) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Cartes", fontSize = 12.sp)
                    }
                    Button(
                        onClick = { vm.navigate(Screen.LEVELS) },
                        modifier = Modifier.weight(1f),
                        colors =
                            ButtonDefaults.buttonColors(containerColor = Gold, contentColor = Ink),
                    ) {
                        Text("Jouer", fontSize = 13.sp)
                    }
                    TextButton(
                        onClick = { vm.navigate(Screen.COMPANY) },
                        modifier = Modifier.weight(1f),
                    ) {
                        Text("Guichet", fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun Levels(ui: UiState, vm: PacoViewModel) {
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(18.dp),
    ) {
        item {
            Text("Un puzzle, une idée à emporter.", style = MaterialTheme.typography.headlineMedium)
        }
        items(6) { i ->
            Row(
                Modifier.fillMaxWidth(),
                horizontalArrangement = if (i % 2 == 0) Arrangement.Start else Arrangement.End,
            ) {
                Panel(
                    Modifier.widthIn(max = 300.dp),
                    if (i <= ui.player.unlocked) Cream else Color(0xFFE0DFDA),
                ) {
                    Text("${i+1}. ${lessons[i].topic}", style = MaterialTheme.typography.titleLarge)
                    Text("${secondsFor(i)} secondes · ${650+i*140} points")
                    Button(
                        onClick = { vm.openLevel(i) },
                        enabled = i <= ui.player.unlocked && !ui.busy,
                    ) {
                        Text(
                            if (i in ui.player.answered) "Rejouer"
                            else if (i in ui.player.completed) "Comprendre avec Paco"
                            else if (i <= ui.player.unlocked) "Jouer" else "Verrouillé"
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun Properties(
    ui: UiState,
    vm: PacoViewModel,
    art: Map<String, ImageBitmap>,
    cards: Boolean,
) {
    val p = ui.player
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Text(
                if (cards) "Les cartes restent acquises après une vente."
                else "${p.plots.size} terrains · ${p.constructions.size} constructions",
                style = MaterialTheme.typography.titleMedium,
            )
        }
        if (!cards)
            item {
                OutlinedButton(onClick = { vm.navigate(Screen.GROWTH) }) {
                    Text("Gérer mes terrains et bâtiments")
                }
            }
        val owned = companies.filter {
            if (cards) it.id in p.cards else (p.holdings[it.id] ?: 0) > 0
        }
        if (owned.isEmpty())
            item {
                Panel {
                    Text("Ta collection attend sa première acquisition.")
                    Button(onClick = { vm.navigate(Screen.COMPANY) }) {
                        Text("Découvrir le guichet")
                    }
                }
            }
        items(owned.size) { i ->
            val c = owned[i]
            Panel {
                Art("buildings/${c.asset}.webp", art, 120.dp)
                Text(c.name, style = MaterialTheme.typography.titleLarge)
                Text("${p.holdings[c.id]} part(s) · ${money(p.price(c.id))} FCFA-jeu / part")
                Button(onClick = { vm.navigate(Screen.COMPANY, c.id) }) {
                    Text("Voir cette action")
                }
            }
        }
        if (!cards)
            items(lands.size) { i ->
                val l = lands[i]
                if (l.id in p.plots)
                    Panel {
                        Text(l.name, style = MaterialTheme.typography.titleMedium)
                        val b = buildings.firstOrNull { it.id == p.constructions[l.id] }
                        if (b != null) Art("buildings/${b.asset}.webp", art, 100.dp)
                        Text(b?.name ?: "Terrain libre")
                        OutlinedButton(onClick = { vm.navigate(Screen.GROWTH) }) {
                            Text("Gérer ce quartier")
                        }
                    }
            }
        if (cards)
            item {
                Text(
                    "${p.answered.size} notions de base et ${p.journey.size}/45 notions du Voyage validées."
                )
            }
    }
}

@Composable
private fun CompanyScreen(ui: UiState, vm: PacoViewModel, art: Map<String, ImageBitmap>) {
    val p = ui.player
    val c = companies.first { it.id == ui.company }
    val price = p.price(c.id)
    val held = p.holdings.getValue(c.id)
    val can = 1 in p.answered && !ui.busy
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Row(
                Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                companies.forEach { company ->
                    FilterChip(
                        selected = company.id == c.id,
                        onClick = { vm.navigate(Screen.COMPANY, company.id) },
                        label = { Text(company.name) },
                    )
                }
            }
        }
        item { Art("buildings/${c.asset}.webp", art, 160.dp) }
        item {
            Text(c.name, style = MaterialTheme.typography.headlineMedium)
            Text("${c.sector} · entreprise fictive")
        }
        item {
            Panel {
                Text("${money(price)} FCFA-jeu / part", style = MaterialTheme.typography.titleLarge)
                Text("$held part(s) détenue(s) · solde ${money(p.cash)} FCFA-jeu")
                Text(
                    "Achat : ${money(price)} + ${fee(price)} de frais = ${money(price+fee(price))} FCFA-jeu."
                )
                Button(
                    onClick = { vm.trade(true) },
                    enabled = can && p.cash >= price + fee(price),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF196B45)),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text(if (held > 0) "Acheter plus" else "Acheter une part")
                }
                Button(
                    onClick = { vm.trade(false) },
                    enabled = can && held > 0,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFA33350)),
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("Vendre")
                }
                Text("Vente d’une part : ${money(price-fee(price))} FCFA-jeu nets après frais.")
                if (!can && 1 !in p.answered)
                    Text("Termine les deux premières notions pour débloquer les échanges.")
            }
        }
        item {
            Text(
                "Valeur des parts : ${money(p.holdingsValue)} FCFA-jeu. Ni les parts ni les constructions ne promettent de revenu."
            )
        }
        item {
            OutlinedButton(
                onClick = vm::drop,
                enabled = 2 in p.answered && !p.dropped && !ui.busy,
            ) {
                Text(if (p.dropped) "Baisse déjà observée" else "Observer la baisse fictive")
            }
        }
        item {
            OutlinedButton(
                onClick = vm::dividend,
                enabled =
                    4 in p.answered &&
                        p.dropped &&
                        !p.dividend &&
                        p.holdings.getValue("cacao") > 0 &&
                        !ui.busy,
            ) {
                Text(if (p.dividend) "Dividende déjà démontré" else "Démontrer le dividende")
            }
        }
    }
}

@Composable
private fun Growth(ui: UiState, vm: PacoViewModel, art: Map<String, ImageBitmap>) {
    val p = ui.player
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Text(
                "${p.plots.size}/6 quartiers · ${money(p.gains)} FCFA-jeu gagnés",
                style = MaterialTheme.typography.titleLarge,
            )
            Text(
                "Gagne des récompenses, achète le terrain puis construis. Les bâtiments restent acquis, sans revenu automatique."
            )
        }
        items(lands.size) { i ->
            val land = lands[i]
            val owned = land.id in p.plots
            val built = buildings.firstOrNull { it.id == p.constructions[land.id] }
            Panel {
                Text(land.name, style = MaterialTheme.typography.titleLarge)
                when {
                    !owned -> {
                        Text(
                            "Terrain : ${land.price} FCFA-jeu · seuil ${land.gains} de récompenses"
                        )
                        if (i > 0 && lands[i - 1].id !in p.plots)
                            Text("Acquiers d’abord le quartier précédent.")
                        else if (p.gains < land.gains)
                            Text("Encore ${land.gains-p.gains} FCFA-jeu à gagner.")
                        Button(
                            onClick = { vm.buyLand(land.id) },
                            enabled =
                                !ui.busy &&
                                    p.cash >= land.price &&
                                    p.gains >= land.gains &&
                                    (i == 0 || lands[i - 1].id in p.plots),
                        ) {
                            Text("Acheter le terrain")
                        }
                    }
                    built != null -> {
                        Art("buildings/${built.asset}.webp", art, 130.dp)
                        Text(built.name)
                        Text("Construit · conservé dans ta ville")
                    }
                    else -> {
                        Text("Terrain acquis. Choisis un bâtiment :")
                        buildings.forEach { b ->
                            OutlinedButton(
                                onClick = { vm.build(land.id, b.id) },
                                enabled = !ui.busy && p.cash >= b.cost,
                                modifier = Modifier.fillMaxWidth(),
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Art("buildings/${b.asset}.webp", art, 48.dp)
                                    Text("${b.name}\n${b.cost} FCFA-jeu", Modifier.weight(1f))
                                }
                            }
                        }
                    }
                }
            }
        }
        item { Text("Solde disponible : ${money(p.cash)} FCFA-jeu") }
    }
}

@Composable
private fun Journey(ui: UiState, vm: PacoViewModel) {
    var destination by remember { mutableStateOf<Int?>(null) }
    var selected by remember { mutableStateOf<Pair<Int, Int>?>(null) }
    var feedback by remember { mutableStateOf<String?>(null) }
    LazyColumn(
        contentPadding = PaddingValues(20.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        item {
            Text(
                "15 destinations · ${ui.player.journey.size}/45 notions",
                style = MaterialTheme.typography.titleLarge,
            )
            Text(
                "Une première bonne réponse rapporte 300 FCFA-jeu. Revoir une notion ne verse pas une nouvelle récompense."
            )
        }
        items(ui.destinations.size) { i ->
            val d = ui.destinations[i]
            val unlocked = i == 0 || (0..2).all { (i - 1) * 3 + it in ui.player.journey }
            Panel {
                Text("${i+1}. ${d.name}", style = MaterialTheme.typography.titleLarge)
                Text("${d.country} · ${d.topic}")
                TextButton(onClick = { destination = if (destination == i) null else i }) {
                    Text(if (destination == i) "Réduire" else "Découvrir")
                }
                if (destination == i) {
                    Text(d.intro)
                    Text(d.reminder, fontWeight = FontWeight.Bold)
                    d.questions.forEachIndexed { q, _ ->
                        Button(
                            onClick = {
                                selected = i to q
                                feedback = null
                            },
                            enabled = unlocked && !ui.busy,
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text(
                                "Notion ${q+1} · ${if(i*3+q in ui.player.journey)"revoir" else "+300 FCFA-jeu"}"
                            )
                        }
                    }
                    if (!unlocked) Text("Termine les trois notions de la destination précédente.")
                }
            }
        }
    }
    selected?.let { (city, q) ->
        val question = ui.destinations[city].questions[q]
        val order = question.answers.indices.map { (it + city + q + 1) % question.answers.size }
        AlertDialog(
            onDismissRequest = { if (!ui.busy) selected = null },
            title = { Text(question.text) },
            text = {
                Column(
                    Modifier.verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    order.forEach { i ->
                        OutlinedButton(
                            onClick = {
                                if (i == 0) {
                                    vm.answerJourney(city, q)
                                    feedback = question.explanation
                                } else feedback = "Essaie encore : relis la notion de Paco."
                            },
                            enabled = !ui.busy,
                            modifier = Modifier.fillMaxWidth(),
                        ) {
                            Text(question.answers[i])
                        }
                    }
                    feedback?.let {
                        Text(it, Modifier.semantics { liveRegion = LiveRegionMode.Polite })
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { selected = null }, enabled = !ui.busy) { Text("Fermer") }
            },
        )
    }
}

@Composable
private fun LessonDialog(
    level: Int,
    ui: UiState,
    vm: PacoViewModel,
    art: Map<String, ImageBitmap>,
) {
    val lesson = lessons[level]
    var selected by remember(level) { mutableStateOf<Int?>(null) }
    var checked by remember(level) { mutableStateOf(false) }
    AlertDialog(
        onDismissRequest = vm::dismissLesson,
        title = { Text("Une idée à emporter · ${lesson.topic}") },
        text = {
            Column(
                Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                Art("paco/expliquer.webp", art)
                Text(lesson.question)
                lesson.options.forEachIndexed { i, text ->
                    OutlinedButton(
                        onClick = {
                            selected = i
                            checked = false
                        },
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        Text("${if(selected==i)"• " else ""}$text")
                    }
                }
                if (checked)
                    Text(
                        if (selected == lesson.answer) lesson.explanation
                        else "Essaie encore : une bonne réponse reste possible.",
                        Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                    )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    if (checked && selected == lesson.answer) vm.learn(level) else checked = true
                },
                enabled = selected != null && !ui.busy,
            ) {
                Text(if (checked && selected == lesson.answer) "Valider la notion" else "Vérifier")
            }
        },
        dismissButton = { TextButton(onClick = vm::dismissLesson) { Text("Plus tard") } },
    )
}

@Composable
private fun SettingsScreen(ui: UiState, vm: PacoViewModel) {
    val context = LocalContext.current
    var draft by remember { mutableStateOf("") }
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Musique", Modifier.weight(1f))
            Switch(checked = ui.music, onCheckedChange = { vm.toggleMusic() })
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Bruitages", Modifier.weight(1f))
            Switch(checked = ui.sfx, onCheckedChange = { vm.toggleSfx() })
        }
        Button(onClick = { vm.navigate(Screen.HISTORY) }) { Text("Mon carnet") }
        Text(
            "PACO Kotlin · version Android native indépendante. Données locales, monnaie fictive. La version Flutter n’est pas modifiée."
        )
        Text("Sauvegarde manuelle", style = MaterialTheme.typography.titleLarge)
        OutlinedButton(
            onClick = {
                (context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager)
                    .setPrimaryClip(ClipData.newPlainText("PACO v3", vm.exportSave()))
            }
        ) {
            Text("Copier ma sauvegarde JSON")
        }
        OutlinedTextField(
            value = draft,
            onValueChange = { if (it.length <= 131072) draft = it },
            label = { Text("Coller une sauvegarde PACO v1, v2 ou v3") },
            modifier = Modifier.fillMaxWidth().heightIn(min = 100.dp),
            maxLines = 6,
        )
        Button(onClick = { vm.previewImport(draft) }, enabled = draft.isNotBlank() && !ui.busy) {
            Text("Vérifier puis importer")
        }
        Text(
            "L’import requiert un export explicite. Kotlin ne lit pas les données privées de Flutter ou d’une autre application. Les options de réduction des animations du téléphone sont respectées."
        )
    }
}
