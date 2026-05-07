package main

import (
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/widget"
)

func main() {
	pcApp := app.New()
	window := pcApp.NewWindow("Suivi patients")
	window.SetContent(widget.NewLabel("Logiciel praticien"))
	window.ShowAndRun()
}
