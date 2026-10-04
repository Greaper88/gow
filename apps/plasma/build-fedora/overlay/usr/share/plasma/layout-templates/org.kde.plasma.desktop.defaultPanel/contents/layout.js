// Seed the container panel once. Plasma persists later user customizations.
var panel = new Panel;
panel.location = "bottom";
panel.height = 44;
var launcher = panel.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("favorites", ["org.kde.discover.desktop", "org.kde.dolphin.desktop",
    "org.kde.konsole.desktop", "org.kde.kate.desktop", "systemsettings.desktop", "gow-power-off.desktop"]);
launcher.writeConfig("primaryActions", 3);
launcher.writeConfig("systemFavorites", ["logout"]);
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", ["applications:org.kde.discover.desktop",
    "applications:org.kde.dolphin.desktop", "applications:org.kde.konsole.desktop"]);
panel.addWidget("org.kde.plasma.marginsseparator");
var tray = panel.addWidget("org.kde.plasma.systemtray");
tray.currentConfigGroup = ["General"];
tray.writeConfig("extraItems", ["org.kde.plasma.volume", "org.kde.plasma.notifications", "org.kde.plasma.clipboard"]);
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.showdesktop");
