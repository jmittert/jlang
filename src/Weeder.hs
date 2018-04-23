module Weeder where
import qualified Ast.ParsedAst as PA
import qualified Ast.WeededAst as WA
import Control.Monad
import Data.List
import qualified Data.Map.Strict as M
import Lib.Types

weeder :: M.Map ModulePath PA.Module-> Either String (M.Map ModulePath WA.Module)
weeder mods = forM mods weedProg

weedProg :: PA.Module -> Either String WA.Module
weedProg (PA.Module name  imprts funcs) = WA.Module (fileToModulePath name) imprts <$> forM funcs weedFunc

weedFunc :: PA.Function -> Either String WA.Function
weedFunc (PA.Func tpe name args stmnts exp) = do
  let duplicateDefs = any (\x -> length x > 1) . group . sort . map snd
  if duplicateDefs args
    then Left ("Duplicate argument definitions in " ++ show name)
    else return $ WA.Func tpe name args (weedStmnt <$> stmnts) (weedExpr exp)
weedFunc (PA.Proc name args stmnts) = do
  let duplicateDefs = any (\x -> length x > 1) . group . sort . map snd
  if duplicateDefs args
    then Left ("Duplicate argument definitions in " ++ show name)
    else return $ WA.Proc name args (weedStmnt <$> stmnts)
weedFunc (PA.CFunc tpe name args body) = do
  let duplicateDefs = any (\x -> length x > 1) . group . sort . map snd
  if duplicateDefs args
    then Left ("Duplicate argument definitions in " ++ show name)
    else return $ WA.CFunc tpe name args body

weedStmnt :: PA.Statement -> WA.Statement
weedStmnt (PA.SExpr expr) = WA.SExpr $ weedExpr expr
weedStmnt (PA.SDecl name tpe) = WA.SDecl name tpe
weedStmnt (PA.SDeclArr name tpe exprs) = WA.SDeclArr name tpe (map weedExpr exprs)
weedStmnt (PA.SDeclAssign name tpe expr) = WA.SDeclAssign name tpe (weedExpr expr)
weedStmnt (PA.SBlock stmnts) = WA.SBlock $ weedStmnt <$> stmnts
weedStmnt (PA.SWhile expr stmnt) = WA.SWhile (weedExpr expr) (weedStmnt stmnt)
weedStmnt (PA.SIf expr stmnt) = WA.SIf (weedExpr expr) (weedStmnt stmnt)
weedStmnt (PA.ForEach name expr stmnt) = WA.ForEach name (weedExpr expr) (weedStmnt stmnt)

weedExpr :: PA.Expr -> WA.Expr
weedExpr (PA.BOp op exp1 exp2) = WA.BOp op (weedExpr exp1) (weedExpr exp2)
weedExpr (PA.EAssign name e) = WA.EAssign name (weedExpr e)
weedExpr (PA.UOp op e) = WA.UOp op (weedExpr e)
weedExpr (PA.Lit l sz s) = WA.Lit l sz s
weedExpr (PA.Var v) = WA.Var v
weedExpr (PA.Ch c) = WA.Ch c
weedExpr (PA.EAssignArr e1 e2 e3) = WA.EAssignArr (weedExpr e1) (weedExpr e2) (weedExpr e3)
weedExpr (PA.Call name exprs) = WA.Call name (map weedExpr exprs)
