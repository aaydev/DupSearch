object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 371
  ClientWidth = 679
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  TextHeight = 15
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 679
    Height = 129
    Align = alTop
    TabOrder = 0
    object LabeledEditMasterFolder: TLabeledEdit
      Left = 16
      Top = 32
      Width = 321
      Height = 23
      EditLabel.Width = 72
      EditLabel.Height = 15
      EditLabel.Caption = 'Master Folder'
      TabOrder = 0
      Text = ''
    end
    object LabeledEditWorkFolder: TLabeledEdit
      Left = 16
      Top = 80
      Width = 321
      Height = 23
      EditLabel.Width = 64
      EditLabel.Height = 15
      EditLabel.Caption = 'Work Folder'
      TabOrder = 1
      Text = ''
    end
    object ButtonBuildIndex: TButton
      Left = 352
      Top = 31
      Width = 75
      Height = 25
      Action = ActionBuildIndex
      TabOrder = 2
    end
    object ButtonSort: TButton
      Left = 352
      Top = 80
      Width = 75
      Height = 25
      Action = ActionSort
      TabOrder = 3
    end
  end
  object RichEdit1: TRichEdit
    Left = 0
    Top = 129
    Width = 679
    Height = 242
    Align = alClient
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object ActionManager1: TActionManager
    Left = 40
    Top = 160
    StyleName = 'Platform Default'
    object ActionBuildIndex: TAction
      Caption = 'Build Index'
      OnExecute = ActionBuildIndexExecute
    end
    object ActionSort: TAction
      Caption = 'Sort'
      OnExecute = ActionSortExecute
    end
  end
end
