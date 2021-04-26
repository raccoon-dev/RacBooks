object dmMain: TdmMain
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 203
  Width = 384
  object conMain: TFDConnection
    Params.Strings = (
      'OpenMode=ReadWrite'
      'DriverID=SQLite'
      'StringFormat=Unicode')
    AfterConnect = conMainAfterConnect
    Left = 24
    Top = 24
  end
  object fdPhysSQLite1: TFDPhysSQLiteDriverLink
    Left = 96
    Top = 24
  end
  object fdCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    ScreenCursor = gcrDefault
    Left = 176
    Top = 24
  end
  object qFolders: TFDQuery
    Connection = conMain
    SQL.Strings = (
      'SELECT fo.*,'
      '       COUNT(fi.id) AS files_nr'
      '  FROM folders fo'
      '  LEFT JOIN files fi'
      '    ON fi.folder_id = fo.id'
      ' GROUP BY fo.name'
      ' ORDER BY fo.name')
    Left = 24
    Top = 80
  end
  object qFiles: TFDQuery
    Connection = conMain
    SQL.Strings = (
      'SELECT *'
      '  FROM files'
      ' WHERE folder_id=:ID'
      'ORDER BY name')
    Left = 72
    Top = 80
    ParamData = <
      item
        Name = 'ID'
        DataType = ftLargeint
        ParamType = ptInput
        Value = Null
      end>
  end
  object tmrCalcSha: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrCalcShaTimer
    Left = 248
    Top = 24
  end
  object qSha: TFDQuery
    Connection = conMain
    SQL.Strings = (
      'SELECT fi.id,'
      '       fi.name,'
      '       fi.path,'
      '       fi.ext,'
      '       fo.path AS path_base'
      '  FROM files fi,'
      '       folders fo'
      ' WHERE fi.sha = '#39#39
      '   AND fi.folder_id = fo.id'
      ' ORDER BY fi.id'
      ' LIMIT 1')
    Left = 120
    Top = 80
  end
end
